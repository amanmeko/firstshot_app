import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TransferCreditPage extends StatefulWidget {
  const TransferCreditPage({super.key});

  @override
  State<TransferCreditPage> createState() => _TransferCreditPageState();
}

class _TransferCreditPageState extends State<TransferCreditPage> {
  int _selectedAmount = 100;
  int _selectedMethod = 0;
  final TextEditingController phoneController = TextEditingController();

  final List<int> amounts = [50, 100, 150, 200];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF9FBFD),
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader("FirstShot Credits Transfer"),
              const SizedBox(height: 16),
              const Text("Select your Amount", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: amounts.map((amt) {
                  return ChoiceChip(
                    label: Text("RM $amt\n+ 1.5% Tax", textAlign: TextAlign.center),
                    selected: _selectedAmount == amt,
                    selectedColor: const Color(0xFF4997D0),
                    onSelected: (_) => setState(() => _selectedAmount = amt),
                    labelStyle: TextStyle(color: _selectedAmount == amt ? Colors.white : Colors.black),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text("Select your Topup method", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _paymentMethod(0, 'assets/icons/credit_card.svg', "FPX", "Online Payment"),
                  _paymentMethod(1, 'assets/icons/credit_card.svg', "Credit Card", "Credit Card"),
                ],
              ),
              const SizedBox(height: 24),
              const Text("Enter Receiver Mobile No", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text("+60")),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        hintText: "1XXXXXXXX",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Receiver must Register as Firstshot Mobile User",
                style: TextStyle(fontSize: 12),
              ),
              const Text(
                "User Mobile Number Not Registered!",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total amount", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("RM $_selectedAmount", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 46),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4997D0),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Top Up Now", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _paymentMethod(int index, String iconPath, String label, String subtitle) {
    final isSelected = _selectedMethod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = index),
      child: Container(
        width: 130,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4997D0) : Colors.white,
          border: Border.all(color: const Color(0xFF4997D0)),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 32,
              height: 32,
              colorFilter: isSelected
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final icons = [
      Icons.calendar_today,
      Icons.assignment,
      Icons.home,
      Icons.sports_tennis_rounded,
      Icons.settings,
    ];
    final labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
    return CurvedNavigationBar(
      index: 4,
      backgroundColor: Colors.transparent,
      color: Colors.black,
      height: 65,
      animationDuration: const Duration(milliseconds: 300),
      items: List.generate(icons.length, (i) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icons[i], color: i == 4 ? const Color(0xFF4997D0) : Colors.white, size: 24),
            if (i != 4)
              Text(labels[i], style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        );
      }),
      onTap: (index) {},
    );
  }
}
