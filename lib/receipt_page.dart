import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, dynamic> transactionData;
  final bool isSuccess;

  const ReceiptPage({
    super.key,
    required this.transactionData,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              _buildHeader(context),
              
              // Receipt Card
              _buildReceiptCard(context),
              
              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSuccess 
            ? [const Color(0xFF4997D0), const Color(0xFF2C5AA0)]
            : [const Color(0xFFDC3545), const Color(0xFFC82333)],
        ),
      ),
      child: Column(
        children: [
          // Success/Error Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_rounded : Icons.close_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            isSuccess ? 'Payment Successful!' : 'Payment Failed',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Text(
            isSuccess 
              ? 'Your booking has been confirmed'
              : 'Your payment could not be processed',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          // Transaction Details
          _buildSection(
            title: 'Transaction Details',
            icon: Icons.receipt_rounded,
            children: [
              _buildInfoRow('Transaction ID', transactionData['tranID'] ?? 'N/A'),
              _buildInfoRow('Amount', 'RM ${_formatAmount(transactionData['amount'])}'),
              _buildInfoRow('Payment Method', _formatPaymentMethod(transactionData['channel'])),
              _buildInfoRow('Payment Date', _formatDate(transactionData['paydate'])),
              _buildInfoRow('Status', _getStatusText()),
            ],
          ),
          
          // Booking Details (if available)
          if (transactionData['booking_details'] != null) ...[
            const Divider(height: 1),
            _buildSection(
              title: 'Booking Details',
              icon: Icons.calendar_today_rounded,
              children: [
                _buildInfoRow('Court', transactionData['booking_details']['court_name'] ?? 'N/A'),
                _buildInfoRow('Date', _formatBookingDate(transactionData['booking_details']['booking_date'])),
                _buildInfoRow('Time', '${transactionData['booking_details']['start_time']} - ${transactionData['booking_details']['end_time']}'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4997D0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF4997D0),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSuccess 
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            size: 16,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isSuccess ? 'Confirmed' : 'Failed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSuccess ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText() {
    return isSuccess ? 'Confirmed' : 'Failed';
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Primary Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/booking-list',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.list_rounded),
              label: const Text('View My Bookings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4997D0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Secondary Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/booking',
                  (route) => false,
                );
              },
              icon: Icon(
                isSuccess ? Icons.add_rounded : Icons.refresh_rounded,
              ),
              label: Text(isSuccess ? 'Book Again' : 'Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4997D0),
                side: const BorderSide(color: Color(0xFF4997D0)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Footer Message
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 24,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  isSuccess 
                    ? 'Thank you for choosing FirstShot!\nYou will receive a confirmation email shortly.'
                    : 'If you believe this is an error, please contact our support team.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    try {
      final numAmount = double.tryParse(amount.toString()) ?? 0.0;
      return NumberFormat('#,##0.00').format(numAmount);
    } catch (e) {
      return '0.00';
    }
  }

  String _formatPaymentMethod(String? channel) {
    if (channel == null) return 'Online Payment';
    
    switch (channel.toLowerCase()) {
      case 'credit':
        return 'Credit Card';
      case 'maybank2u':
        return 'Maybank2u';
      case 'cimbclicks':
        return 'CIMB Clicks';
      case 'rhbnow':
        return 'RHB Now';
      case 'hongleongconnect':
        return 'Hong Leong Connect';
      case 'ambank':
        return 'AmBank';
      case 'publicbank':
        return 'Public Bank';
      case 'allianceonline':
        return 'Alliance Online';
      case 'affinonline':
        return 'Affin Online';
      case 'bankislam':
        return 'Bank Islam';
      case 'bankmuamalat':
        return 'Bank Muamalat';
      case 'ocbc':
        return 'OCBC';
      case 'uob':
        return 'UOB';
      case 'hsbc':
        return 'HSBC';
      case 'scb':
        return 'Standard Chartered';
      case 'citibank':
        return 'Citibank';
      default:
        return channel;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatBookingDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
