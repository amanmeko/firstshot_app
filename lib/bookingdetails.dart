import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'services/booking_service.dart';
import 'services/payment_service.dart';
import 'receipt_page.dart';

class BookingDetailsPage extends StatefulWidget {
  final int courtId;
  final String selectedTime;
  final int selectedDuration;
  final double price;
  final String courtName;

  const BookingDetailsPage({
    super.key,
    required this.courtId,
    required this.selectedTime,
    required this.selectedDuration,
    required this.price,
    required this.courtName,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _promoCodeController = TextEditingController();
  bool _isLoading = false;
  String? _promoCodeError;
  double _discount = 0.0;
  String? _promoCodeId;
  double _finalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _finalPrice = widget.price;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _validatePromoCode() async {
    if (_promoCodeController.text.trim().isEmpty) {
      setState(() {
        _promoCodeError = 'Please enter a promo code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _promoCodeError = null;
    });

    try {
      final response = await BookingService.validatePromoCode(
        code: _promoCodeController.text.trim(),
        subtotal: widget.price,
      );

      if (response['success'] == true) {
        final promoCode = response['promoCode'];
        final discount = promoCode['type'] == 'percentage'
            ? (widget.price * promoCode['value']) / 100
            : promoCode['value'].toDouble();

        setState(() {
          _discount = discount;
          _promoCodeId = promoCode['id'].toString();
          _finalPrice = widget.price - _discount;
          _promoCodeError = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promo code applied! Discount: RM ${discount.toStringAsFixed(2)}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _promoCodeError = response['message'] ?? 'Invalid promo code';
          _discount = 0.0;
          _promoCodeId = null;
          _finalPrice = widget.price;
        });
      }
    } catch (e) {
      setState(() {
        _promoCodeError = 'Error validating promo code: $e';
        _discount = 0.0;
        _promoCodeId = null;
        _finalPrice = widget.price;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBooking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storage = const FlutterSecureStorage();
      final customerIdStr = await storage.read(key: 'user_id');
      
      if (customerIdStr == null) {
        throw Exception('Customer ID not found. Please log in again.');
      }

      final customerId = int.tryParse(customerIdStr);
      if (customerId == null) {
        throw Exception('Invalid customer ID.');
      }

      // Calculate end time based on duration
      final startTime = TimeOfDay.fromDateTime(DateFormat('HH:mm').parse(widget.selectedTime));
      final endTime = TimeOfDay(
        hour: (startTime.hour + widget.selectedDuration) % 24,
        minute: startTime.minute,
      );

      final response = await BookingService.createBooking(
        courtId: widget.courtId,
        customerId: customerId,
        bookingDate: DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1))),
        startTime: widget.selectedTime,
        endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        price: _finalPrice,
        paymentMethod: 'online',
        notes: _notesController.text.trim(),
        promoCode: _promoCodeId,
        durationHours: widget.selectedDuration,
      );

      if (response['success'] == true) {
        // Extract sale ID from redirect URL
        final redirectUrl = response['redirect_url'];
        final saleIdMatch = RegExp(r'/payment/initiate/(\d+)').firstMatch(redirectUrl);
        
        if (saleIdMatch != null) {
          final saleId = int.parse(saleIdMatch.group(1)!);
          await _processPayment(saleId);
        } else {
          throw Exception('Could not extract sale ID from response');
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment(int saleId) async {
    try {
      // Show payment processing dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PaymentProcessingDialog(),
      );

      // Step 1: Get payment initiation data
      final paymentData = await PaymentService.initiatePayment(saleId);
      
      if (!paymentData['success']) {
        throw Exception('Failed to get payment data');
      }

      // Step 2: Submit payment to gateway
      final paymentResponse = await PaymentService.submitPayment(paymentData['payment']);
      
      if (PaymentService.isValidPaymentResponse(paymentResponse)) {
        // Step 3: Poll for payment status
        final transactionId = paymentResponse['tranID'];
        final finalStatus = await PaymentService.pollPaymentStatus(transactionId);
        
        // Close processing dialog
        Navigator.of(context).pop();
        
        // Navigate to receipt page
        final isSuccess = finalStatus['status'] == 'completed';
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptPage(
              transactionData: finalStatus['transaction'],
              isSuccess: isSuccess,
            ),
          ),
        );
      } else {
        // Close processing dialog
        Navigator.of(context).pop();
        
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed - invalid response from gateway'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close processing dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      appBar: AppBar(
        title: const Text(
          'Booking Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4997D0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildInfoRow('Court', widget.courtName),
                  _buildInfoRow('Date', DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now().add(const Duration(days: 1)))),
                  _buildInfoRow('Time', '${widget.selectedTime} (${widget.selectedDuration} hour${widget.selectedDuration > 1 ? 's' : ''})'),
                  _buildInfoRow('Duration', '${widget.selectedDuration} hour${widget.selectedDuration > 1 ? 's' : ''}'),
                  
                  const Divider(height: 32),
                  
                  // Price breakdown
                  _buildInfoRow('Base Price', 'RM ${widget.price.toStringAsFixed(2)}'),
                  if (_discount > 0) ...[
                    _buildInfoRow('Discount', '-RM ${_discount.toStringAsFixed(2)}', isDiscount: true),
                  ],
                  const Divider(height: 16),
                  _buildInfoRow(
                    'Total Amount',
                    'RM ${_finalPrice.toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Promo Code Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promo Code (Optional)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoCodeController,
                          decoration: InputDecoration(
                            hintText: 'Enter promo code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            errorText: _promoCodeError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _validatePromoCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4997D0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Notes Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Notes (Optional)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add any special requests or notes...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Checkout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4997D0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Processing...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.payment),
                          const SizedBox(width: 8),
                          Text(
                            'Proceed to Payment - RM ${_finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
              color: isDiscount 
                ? Colors.green 
                : isTotal 
                  ? const Color(0xFF4997D0)
                  : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

// Payment Processing Dialog
class PaymentProcessingDialog extends StatelessWidget {
  const PaymentProcessingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF4997D0),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            const Text(
              'Processing Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please wait while we process your payment...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
