import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final Function(Map<String, dynamic>?) onPaymentComplete;

  const PaymentWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Check if this is the return URL from payment gateway
            if (request.url.contains('/payment/return')) {
              _handlePaymentReturn(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _error = 'Error loading payment page: ${error.description}';
              _isLoading = false;
            });
          },
        ),
      )
      // Note: setCustomHeaders is not available in current webview_flutter version
      ..loadRequest(Uri.parse(widget.paymentUrl));

    // Set a timeout for payment completion
    _timeoutTimer = Timer(const Duration(minutes: 10), () {
      if (mounted) {
        widget.onPaymentComplete(null);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _handlePaymentReturn(String url) async {
    try {
      // Extract parameters from URL
      final uri = Uri.parse(url);
      final params = uri.queryParameters;
      
      print('Payment return URL: $url');
      print('Payment parameters: $params');
      
      if (params.isNotEmpty) {
        // Convert params to Map<String, dynamic>
        final transactionData = Map<String, dynamic>.from(params);
        
        // Check if we have the required parameters
        if (transactionData.containsKey('tranID') && 
            transactionData.containsKey('status')) {
          
          print('Valid payment response received: $transactionData');
          
          // Call the callback with transaction data
          widget.onPaymentComplete(transactionData);
        } else {
          print('Invalid payment response - missing required parameters');
          widget.onPaymentComplete(null);
        }
      } else {
        // No parameters, payment might have been cancelled
        print('No payment parameters found - payment cancelled');
        widget.onPaymentComplete(null);
      }
    } catch (e) {
      print('Error handling payment return: $e');
      // Error handling
      widget.onPaymentComplete(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Payment Gateway',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4997D0),
        iconTheme: const IconThemeData(color: Colors.white),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              widget.onPaymentComplete(null);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_error != null)
            _buildErrorView()
          else
            WebViewWidget(controller: _controller),
          if (_isLoading && _error == null)
            _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF4997D0),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading payment gateway...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'An error occurred while loading the payment page.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isLoading = true;
                  });
                  _controller.reload();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4997D0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  widget.onPaymentComplete(null);
                },
                child: const Text('Cancel Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
