<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use App\Models\Sale;
use App\Models\Transaction;

class PaymentController extends Controller
{
    public function __construct()
    {
        // Exclude CSRF protection for payment routes
        $this->middleware('web')->except(['handleReturn', 'handleCallback']);
    }

    public function initiate(Request $request, Sale $sale)
    {
        $merchantID = 'AMfirstshot';
        $verifyKey  = '2db2413d4c55c2dbcda76d4000ebb535';
    
        $customer = $sale->customer;
        $amount   = number_format((float) $sale->total, 2, '.', '');
    
        $paymentData = [
            'amount'      => $amount,
            'orderid'     => (string) $sale->id,
            'bill_name'   => $customer->name,
            'bill_email'  => $customer->email ?? 'no-email@example.com',
            'bill_mobile' => preg_replace('/\D+/', '', $customer->phone ?? '000000000'),
            'bill_desc'   => "Booking {$sale->id}",
            'cur'         => 'MYR',
            'returnurl'   => route('payment.return'),
            'callbackurl' => route('payment.callback'),
        ];
    
        // FIUU/RMS vcode: MD5(amount + merchantID + orderid + verifyKey)
        $paymentData['vcode'] = md5($amount . $merchantID . $paymentData['orderid'] . $verifyKey);
    
        // Always return JSON for mobile app
        return response()->json([
            'success' => true,
            'payment' => [
                'method'     => 'POST',
                'action_url' => "https://pay.fiuu.com/RMS/pay/{$merchantID}/",
                'params'     => $paymentData,
            ],
        ]);
    }

    public function handleReturn(Request $request)
    {
        Log::info('Payment return received', [
            'method' => $request->method(),
            'params' => $request->all(),
            'headers' => $request->headers->all()
        ]);

        // Always return JSON response for mobile app
        return $this->processPaymentResponse($request, 'return');
    }

    public function handleCallback(Request $request)
    {
        // Callbacks are always server-to-server, so return simple response
        return $this->processPaymentResponse($request, 'callback');
    }

    private function processPaymentResponse(Request $request, $type)
    {
        $secretKey = env('FIUU_SECRET_KEY');
        $params = $request->all();

        Log::info('Payment response received', [
            'type' => $type,
            'params' => $params,
            'method' => $request->method(),
            'headers' => $request->headers->all()
        ]);

        // Check if required parameters exist
        $requiredParams = ['tranID', 'orderid', 'status', 'domain', 'amount', 'currency', 'paydate', 'appcode', 'skey'];
        foreach ($requiredParams as $param) {
            if (!isset($params[$param])) {
                Log::error('Missing required parameter', ['param' => $param, 'params' => $params]);
                return $this->handlePaymentError('Missing required parameter: ' . $param, $type);
            }
        }

        // Validate security hash
        $key0 = md5(
            $params['tranID'] .
                $params['orderid'] .
                $params['status'] .
                $params['domain'] .
                $params['amount'] .
                $params['currency']
        );

        $key1 = md5(
            $params['paydate'] .
                $params['domain'] .
                $key0 .
                $params['appcode'] .
                $secretKey
        );

        if (!hash_equals($params['skey'], $key1)) {
            Log::error('Invalid security hash', [
                'received_skey' => $params['skey'],
                'calculated_key1' => $key1,
                'params' => $params
            ]);
            return $this->handlePaymentError('Security verification failed', $type);
        }
        
        $sale = Sale::find($request->orderid);
        if (!$sale) {
            Log::error('Sale not found', ['orderid' => $request->orderid, 'params' => $params]);
            return $this->handlePaymentError('Invalid sale reference', $type);
        }

        $status = match ($request->status) {
            '00' => 'completed',
            '11' => 'failed',
            '22' => 'pending',
            default => 'unknown'
        };

        try {
            // Create or update transaction record
            $transaction = Transaction::updateOrCreate(
                ['transaction_id' => $request->tranID],
                [
                    'sale_id' => $sale->id,
                    'amount' => $request->amount,
                    'currency' => $request->currency,
                    'status' => $status,
                    'payment_channel' => $request->channel ?? null,
                    'payment_date' => $request->paydate ? \Carbon\Carbon::parse($request->paydate) : null,
                    'app_code' => $request->appcode ?? null,
                    'domain' => $request->domain ?? null,
                    'response_data' => $params,
                ]
            );

            // Update sale status
            $sale->status = $status;
            $sale->save();

            // Update related booking
            $booking = null;
            if ($saleItem = $sale->items()->first()) {
                $booking = $saleItem->booking;
                if ($booking) {
                    $booking->status = match ($status) {
                        'completed' => 'confirmed',
                        'failed' => 'cancelled',
                        default => 'pending'
                    };
                    $booking->save();
                }
            }

            Log::info('Payment processed successfully', [
                'sale_id' => $sale->id,
                'booking_id' => $booking->id ?? null,
                'status' => $status,
                'transaction_id' => $request->tranID
            ]);

            if ($type === 'callback') {
                return response('CBTOKEN:MPSTATOK');
            }

            // For return (user coming back from payment gateway) - Return JSON for mobile app
            $responseData = [
                'success' => true,
                'status' => $status,
                'sale_id' => $sale->id,
                'booking_id' => $booking->id ?? null,
                'transaction' => [
                    'tranID' => $request->tranID,
                    'amount' => $request->amount,
                    'currency' => $request->currency,
                    'channel' => $request->channel,
                    'paydate' => $request->paydate,
                    'appcode' => $request->appcode,
                    'status' => $status,
                ]
            ];

            // Add booking details if available
            if ($booking && $booking->court) {
                $responseData['transaction']['booking_details'] = [
                    'court_name' => $booking->court->name,
                    'booking_date' => $booking->booking_date,
                    'start_time' => $booking->start_time,
                    'end_time' => $booking->end_time,
                ];
            }

            return response()->json($responseData);

        } catch (\Exception $e) {
            Log::error('Error processing payment response', [
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
                'params' => $params
            ]);
            return $this->handlePaymentError('Error processing payment: ' . $e->getMessage(), $type);
        }
    }

    private function handlePaymentError($message, $type)
    {
        Log::error('Payment error', ['message' => $message, 'type' => $type]);
        
        if ($type === 'callback') {
            return response('CBTOKEN:MPSTATOK');
        }

        return response()->json([
            'success' => false,
            'status' => 'failed',
            'message' => $message,
            'transaction' => [
                'status' => 'failed',
                'error' => $message
            ]
        ], 400);
    }

    // API endpoint to check payment status
    public function checkStatus(Request $request)
    {
        $request->validate([
            'transaction_id' => 'required|string',
        ]);

        $transaction = Transaction::where('transaction_id', $request->transaction_id)->first();
        
        if (!$transaction) {
            return response()->json([
                'success' => false,
                'message' => 'Transaction not found'
            ], 404);
        }

        $responseData = [
            'success' => true,
            'status' => $transaction->status,
            'sale_id' => $transaction->sale_id,
            'transaction' => [
                'tranID' => $transaction->transaction_id,
                'amount' => $transaction->amount,
                'currency' => $transaction->currency,
                'channel' => $transaction->payment_channel,
                'paydate' => $transaction->payment_date?->toISOString(),
                'appcode' => $transaction->app_code,
                'status' => $transaction->status,
            ]
        ];

        // Add booking details if available
        if ($transaction->sale && $transaction->sale->items->first() && $transaction->sale->items->first()->booking) {
            $booking = $transaction->sale->items->first()->booking;
            $responseData['transaction']['booking_details'] = [
                'court_name' => $booking->court->name ?? 'N/A',
                'booking_date' => $booking->booking_date,
                'start_time' => $booking->start_time,
                'end_time' => $booking->end_time,
            ];
        }

        return response()->json($responseData);
    }
}
