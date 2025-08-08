import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'services/booking_service.dart';
import 'models/court.dart';
import 'payment_webview_page.dart';

class BookingDetailsPage extends StatefulWidget {
  final Court selectedCourt;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final String selectedDuration;
  final int customerId;

  const BookingDetailsPage({
    super.key,
    required this.selectedCourt,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedDuration,
    required this.customerId,
  });

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  int _selectedIndex = 0;
  final TextEditingController _voucherController = TextEditingController();
  bool isLoading = false;
  String? promoCodeMessage;
  bool isPromoCodeValid = false;
  double discount = 0.0;

  final Map<String, int> gearQuantities = {
    "Rent Paddles": 0,
    "Rent Balls": 0,
    "Ball Machine": 0,
  };

  final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.assignment,
    Icons.home,
    Icons.sports_tennis_rounded,
    Icons.settings,
  ];

  void _adjustGear(String gear, int delta) {
    setState(() {
      final newQty = gearQuantities[gear]! + delta;
      gearQuantities[gear] = newQty < 0 ? 0 : newQty;
    });
  }

  double get _subtotal {
    final durationHours = int.parse(widget.selectedDuration.split(' ')[0]);
    final basePrice = widget.selectedCourt.price * durationHours;
    final gearPrice = gearQuantities.values.reduce((a, b) => a + b) * 15.0;
    return basePrice + gearPrice;
  }

  double get _total {
    return _subtotal - discount;
  }

  Future<void> _validatePromoCode() async {
    if (_voucherController.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await BookingService.validatePromoCode(
        code: _voucherController.text.trim(),
        subtotal: _subtotal,
      );

      setState(() {
        isLoading = false;
        isPromoCodeValid = response['success'];
        promoCodeMessage = response['message'];
        
        if (response['success'] && response['promoCode'] != null) {
          final promoCode = response['promoCode'];
          if (promoCode['type'] == 'percentage') {
            discount = (_subtotal * promoCode['value']) / 100;
          } else {
            discount = promoCode['value'].toDouble();
          }
        } else {
          discount = 0.0;
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        isPromoCodeValid = false;
        promoCodeMessage = 'Error validating promo code: $e';
        discount = 0.0;
      });
    }
  }

  Future<void> _handleCheckout() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Calculate end time based on duration
      final durationHours = int.parse(widget.selectedDuration.split(' ')[0]);
      final startTime = widget.selectedTime;
      final endTime = TimeOfDay(
        hour: (startTime.hour + durationHours) % 24,
        minute: startTime.minute,
      );

      final response = await BookingService.createBooking(
        courtId: widget.selectedCourt.id,
        customerId: widget.customerId,
        bookingDate: DateFormat('yyyy-MM-dd').format(widget.selectedDate),
        startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        price: _total,
        paymentMethod: 'online',
        notes: 'Booking from mobile app',
        promoCode: isPromoCodeValid ? _voucherController.text.trim() : null,
      );

      setState(() { isLoading = false; });

      if (response['success'] == true) {
        // Case 1: direct URL
        final paymentUrl = response['payment_url'] ?? response['redirect_url'] ?? response['url'];
        if (paymentUrl is String && paymentUrl.isNotEmpty) {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentWebViewPage(url: paymentUrl, title: 'Payment'),
            ),
          );
          return;
        }

        // Case 2: backend returned structured POST form details
        final payment = response['payment'];
        if (payment is Map) {
          final method = payment['method'];
          final actionUrl = payment['action_url'];
          final params = payment['params'];
          if (method == 'POST' && actionUrl is String && params is Map) {
            String _escapeHtml(Object? value) {
              final s = (value ?? '').toString();
              return s
                  .replaceAll('&', '&amp;')
                  .replaceAll('<', '&lt;')
                  .replaceAll('>', '&gt;')
                  .replaceAll('"', '&quot;')
                  .replaceAll("'", '&#39;');
            }

            final inputs = params.entries
                .map((e) => '<input type="hidden" name="${_escapeHtml(e.key)}" value="${_escapeHtml(e.value)}">')
                .join();
            final html = '<!doctype html><html><head><meta charset="utf-8"></head><body onload="document.f.submit()">\n'
                '<form name="f" method="post" action="${_escapeHtml(actionUrl)}" accept-charset="UTF-8">$inputs</form>'
                '<noscript><button type="submit">Continue</button></noscript>'
                '</body></html>';
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PaymentWebViewPage(html: html, title: 'Payment'),
              ),
            );
            return;
          }
        }
        // No URL: fallback to success dialog
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Successful!'),
            content: Text('Your booking has been created. Booking ID: ${response['booking']?['id'] ?? '-'}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Booking failed')),
        );
      }
    } catch (e) {
      setState(() { isLoading = false; });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating booking: $e')),
      );
    }
  }

  void _onBottomTap(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/booking');
        break;
      case 1:
        Navigator.pushNamed(context, '/coaching');
        break;
      case 2:
        Navigator.pushNamed(context, '/main');
        break;
      case 3:
        Navigator.pushNamed(context, '/instructors');
        break;
      case 4:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              _buildCourtBox(),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text("Need Gears for Rental?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 12),
              _buildGearList(),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Price Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildPriceRow("Total Hours", widget.selectedDuration),
              _buildPriceRow("Court Price", "RM ${widget.selectedCourt.price * int.parse(widget.selectedDuration.split(' ')[0])}"),
              if (gearQuantities.values.reduce((a, b) => a + b) > 0) ...[
                for (var entry in gearQuantities.entries)
                  if (entry.value > 0)
                    _buildPriceRow("Add On – ${entry.key} (${entry.value})", "RM ${entry.value * 15}"),
              ],
              if (discount > 0) ...[
                _buildPriceRow("Discount", "-RM ${discount.toStringAsFixed(2)}", isBold: true),
              ],
              const Divider(thickness: 1, height: 20),
              _buildPriceRow("Grand Total", "RM ${_total.toStringAsFixed(2)}", isBold: true),
              const SizedBox(height: 16),
              _buildVoucherInput(),
              const SizedBox(height: 12),
              _buildCheckoutButton(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        backgroundColor: Colors.transparent,
        color: Colors.black,
        height: 65,
        animationDuration: const Duration(milliseconds: 300),
        items: List.generate(_icons.length, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _icons[index],
                color: _selectedIndex == index ? const Color(0xFF4997D0) : Colors.white,
                size: 24,
              ),
              if (_selectedIndex != index)
                Text(_labels[index], style: const TextStyle(color: Colors.white, fontSize: 10)),
            ],
          );
        }),
        onTap: _onBottomTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        ClipPath(
          clipper: CustomDiagonalClipper(),
          child: SvgPicture.asset(
            'assets/images/orderbanner.svg',
            height: 170,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 30,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        const Positioned(
          bottom: 8,
          left: 16,
          child: Text("Booking Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildCourtBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4997D0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.selectedCourt.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("${DateFormat('MMM dd, yyyy').format(widget.selectedDate)} at ${widget.selectedTime.format(context)}", 
                     style: const TextStyle(color: Colors.white, fontSize: 12)),
                Text("Duration: ${widget.selectedDuration}", style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
            Text("RM${widget.selectedCourt.price}/hr", style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildGearList() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: gearQuantities.keys.map((gear) => _buildAddon(gear)).toList(),
      ),
    );
  }

  Widget _buildAddon(String title) {
    int quantity = gearQuantities[title]!;
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("RM 15 / hr", style: TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _counterButton(Icons.remove, () => _adjustGear(title, -1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text("$quantity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              _counterButton(Icons.add, () => _adjustGear(title, 1)),
            ],
          )
        ],
      ),
    );
  }

  Widget _counterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: Colors.red, size: 20),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildVoucherInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          TextField(
            controller: _voucherController,
            decoration: InputDecoration(
              hintText: "Enter your Voucher Code",
              prefixIcon: const Icon(Icons.card_giftcard),
              suffixIcon: isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _validatePromoCode,
                  ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isPromoCodeValid ? Colors.green : Colors.blueAccent,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isPromoCodeValid ? Colors.green : Colors.blueAccent,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _validatePromoCode(),
          ),
          if (promoCodeMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              promoCodeMessage!,
              style: TextStyle(
                color: isPromoCodeValid ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleCheckout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4997D0),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Text("Checkout Now", style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}

class CustomDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 60);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
