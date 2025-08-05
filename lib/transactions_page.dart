import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  int _selectedIndex = 4;
  int _currentPage = 1;

  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.assignment,
    Icons.home,
    Icons.sports_tennis_rounded,
    Icons.settings,
  ];

  final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];

  final List<Map<String, String>> page1Transactions = [
    {"id": "11234", "date": "12.12.2025", "time": "12.20PM", "amount": "RM 120.00"},
    {"id": "11235", "date": "13.12.2025", "time": "3.00PM", "amount": "RM 88.00"},
    {"id": "11236", "date": "14.12.2025", "time": "5.45PM", "amount": "RM 60.00"},
    {"id": "11237", "date": "15.12.2025", "time": "10.00AM", "amount": "RM 35.50"},
  ];

  final List<Map<String, String>> page2Transactions = [
    {"id": "11238", "date": "16.12.2025", "time": "9.30AM", "amount": "RM 20.00"},
    {"id": "11239", "date": "17.12.2025", "time": "1.15PM", "amount": "RM 75.00"},
    {"id": "11240", "date": "18.12.2025", "time": "4.00PM", "amount": "RM 150.00"},
    {"id": "11241", "date": "19.12.2025", "time": "11.20AM", "amount": "RM 110.00"},
  ];

  List<Map<String, String>> get currentTransactions =>
      _currentPage == 1 ? page1Transactions : page2Transactions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
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
        onTap: (index) {
          // Optional: navigate to other pages
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Transactions & Credit Records",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _iconBox('assets/icons/credit_card.svg', 'Manage\nCredit / Debit Card', () {
                    Navigator.pushNamed(context, '/manage_card');
                  }),
                  _iconBox('assets/icons/wallet.svg', 'Transfer Credits\nTo Others', () {
                    Navigator.pushNamed(context, '/transfer_credit');
                  }),
                ],
              ),
            ),

            // Wallet Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D2FDD), Color(0xFF8C28D3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_balance, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("FirstShot", style: TextStyle(color: Colors.white, fontSize: 16)),
                        SizedBox(height: 4),
                        Text("Total Balance :", style: TextStyle(color: Colors.white, fontSize: 12)),
                        Text("RM 2.20", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text("Heng Meng", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text("CREDIT", style: TextStyle(color: Colors.white)),
                      Text("***", style: TextStyle(color: Colors.white)),
                      SizedBox(height: 20),
                      Text("click to topup", style: TextStyle(color: Colors.white, fontSize: 10)),
                      Icon(Icons.open_in_new, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),

            // Transaction Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Expanded(child: Text("Transaction List", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Transaction List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: currentTransactions.length,
                itemBuilder: (context, index) {
                  final tx = currentTransactions[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF4997D0)),
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            tx["id"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tx["date"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tx["time"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            tx["amount"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          ),
                          child: const Text("Receipt", style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Next/Previous Page
            Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 35),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPage = _currentPage == 1 ? 2 : 1;
                    });
                  },
                  child: Text(
                    _currentPage == 1 ? "Next Page >>" : "<< Previous Page",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(String iconAsset, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF4997D0)),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              iconAsset,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.blue, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
