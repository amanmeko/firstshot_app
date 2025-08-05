import 'package:flutter/material.dart';
import 'booking_details.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  void _showPDFPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PDF Receipt'),
        content: const Text('PDF generated and ready to share via WhatsApp.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // TODO: implement actual WhatsApp sharing here
              Navigator.pop(context);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.blue, size: 40),
              const SizedBox(height: 10),
              const Text('RM 70.80', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
              const SizedBox(height: 16),

              // Receipt Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    _infoRow('Ref Number', '000085752257'),
                    _infoRow('Payment Time', '25-02-2023, 13:22:16'),
                    _infoRow('Payment Method', 'Toyyibpay'),

                    const SizedBox(height: 16),
                    const Text('Court A', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('12.00pm - 1.00 pm'),
                    const Text('12.12.2025'),

                    const Divider(height: 24, thickness: 1),

                    _infoRow('Amount', 'RM 70.00', bold: true),
                    _infoRow('Admin Fee', 'RM 0.80'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment Status', style: TextStyle(color: Colors.grey.shade600)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("Success", style: TextStyle(color: Colors.green)),
                        )
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Get PDF Receipt Button
              ElevatedButton.icon(
                onPressed: () => _showPDFPopup(context),
                icon: const Icon(Icons.download),
                label: const Text('Get PDF Receipt'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              const SizedBox(height: 12),

              // Go to Booking Details
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingDetailsPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4997D0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Go to Booking Details', style: TextStyle(color: Colors.white)),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/main');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4997D0)), // Blue border
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Colors.transparent,
                ),
                child: const Text(
                  'Go to Main Page',
                  style: TextStyle(color: Colors.black), // Black text
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
