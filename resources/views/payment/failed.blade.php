<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Failed - FirstShot</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #DC3545, #C82333);
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
        .error-icon {
            width: 80px;
            height: 80px;
            background: #DC3545;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 20px;
        }
        .error-icon::before {
            content: "✕";
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
        .button.secondary {
            background: #6B7280;
        }
        .button.secondary:hover {
            background: #4B5563;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="error-icon"></div>
        <h1>Payment Failed</h1>
        <p>Your payment could not be processed. Please try again or contact support if the problem persists.</p>
        
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
                <span class="detail-value">Failed</span>
            </div>
            @if(isset($message))
            <div class="detail-row">
                <span class="detail-label">Error:</span>
                <span class="detail-value">{{ $message }}</span>
            </div>
            @endif
        </div>
        @endif
        
        <div>
            <a href="/booking" class="button">Try Again</a>
            <a href="/" class="button secondary">Return to Home</a>
        </div>
    </div>
</body>
</html>
