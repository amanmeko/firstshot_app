<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Successful - FirstShot</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #4997D0, #2C5AA0);
            margin: 0;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            border-radius: 16px;
            padding: 40px;
            text-align: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            max-width: 500px;
            width: 100%;
        }
        .success-icon {
            width: 80px;
            height: 80px;
            background: #10B981;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
        }
        .success-icon::before {
            content: "✓";
            color: white;
            font-size: 40px;
            font-weight: bold;
        }
        h1 {
            color: #1F2937;
            margin-bottom: 10px;
        }
        p {
            color: #6B7280;
            margin-bottom: 30px;
        }
        .transaction-details {
            background: #F9FAFB;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
            text-align: left;
        }
        .transaction-details h3 {
            margin-top: 0;
            color: #374151;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
        }
        .detail-label {
            color: #6B7280;
            font-weight: 500;
        }
        .detail-value {
            color: #1F2937;
            font-weight: 600;
        }
        .button {
            background: #4997D0;
            color: white;
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            text-decoration: none;
            display: inline-block;
            margin: 10px;
            font-weight: 500;
        }
        .button:hover {
            background: #3B82F6;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="success-icon"></div>
        <h1>Payment Successful!</h1>
        <p>Your booking has been confirmed. Thank you for choosing FirstShot!</p>
        
        @if(isset($transaction))
        <div class="transaction-details">
            <h3>Transaction Details</h3>
            <div class="detail-row">
                <span class="detail-label">Transaction ID:</span>
                <span class="detail-value">{{ $transaction['tranID'] ?? 'N/A' }}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Amount:</span>
                <span class="detail-value">RM {{ number_format($transaction['amount'] ?? 0, 2) }}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Status:</span>
                <span class="detail-value">Completed</span>
            </div>
            @if(isset($transaction['booking_details']))
            <div class="detail-row">
                <span class="detail-label">Court:</span>
                <span class="detail-value">{{ $transaction['booking_details']['court_name'] ?? 'N/A' }}</span>
            </div>
            @endif
        </div>
        @endif
        
        <div>
            <a href="/" class="button">Return to Home</a>
            <a href="/bookings" class="button">View My Bookings</a>
        </div>
    </div>
</body>
</html>
