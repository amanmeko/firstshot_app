import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class ManageCardPage extends StatefulWidget {
  const ManageCardPage({super.key});

  @override
  State<ManageCardPage> createState() => _ManageCardPageState();
}

class _ManageCardPageState extends State<ManageCardPage> {
  int _selectedIndex = 4;
  bool saveInfo = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();

  final List<Map<String, String>> _cards = [
    {
      'bank': 'CIMB Card',
      'number': '0000 2363 8364 ****',
      'expiry': '5/23',
      'name': 'Daniel Chan',
    },
    {
      'bank': 'Maybank Card',
      'number': '0000 1111 2222 ****',
      'expiry': '7/25',
      'name': 'Siti Aisyah',
    },
    {
      'bank': 'HSBC Card',
      'number': '0000 9999 8888 ****',
      'expiry': '11/24',
      'name': 'John Lee',
    },
  ];

  void _deleteCard(int index) {
    setState(() => _cards.removeAt(index));
  }

  void _addNewCard() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _cards.add({
          'bank': 'My New Card',
          'number': _cardNumberController.text,
          'expiry': _expiryController.text,
          'name': _cardNameController.text,
        });
        _cardNameController.clear();
        _cardNumberController.clear();
        _expiryController.clear();
        _cvcController.clear();
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Card Added"),
          content: const Text("Your card was successfully saved."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader("Manage Card"),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _cards.length,
                  itemBuilder: (context, index) {
                    final card = _cards[index];
                    return Dismissible(
                      key: Key(card['number']! + index.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteCard(index),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _buildCardPreview(
                          bank: card['bank']!,
                          number: card['number']!,
                          expiry: card['expiry']!,
                          name: card['name']!,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Enter New Credit / Debit Card Details",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildInput("Cardholder name", controller: _cardNameController),
                    _buildInput(
                      "Card number",
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      suffixIcon: Image.asset('assets/icons/mastercard.png', width: 24),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            "Exp Month & Year",
                            controller: _expiryController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [ExpiryDateFormatter()],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildInput(
                            "CVC",
                            controller: _cvcController,
                            obscure: true,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: saveInfo,
                          activeColor: Colors.lightBlue,
                          onChanged: (value) {
                            setState(() => saveInfo = value ?? false);
                          },
                        ),
                        const Text("Save your information card", style: TextStyle(color: Colors.lightBlue)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _addNewCard,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Add New Card",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildCardPreview({
    required String bank,
    required String number,
    required String expiry,
    required String name,
  }) {
    return Container(
      width: 300,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF2D2FDD), Color(0xFF8C28D3)]),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bank, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const Spacer(),
          Text(number.isNotEmpty ? number : "**** **** **** ****",
              style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text("VALID THRU $expiry    ***", style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInput(
      String label, {
        required TextEditingController controller,
        bool obscure = false,
        Widget? suffixIcon,
        TextInputType? keyboardType,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        obscuringCharacter: '*',
        keyboardType: keyboardType ?? TextInputType.text,
        inputFormatters: inputFormatters,
        validator: (value) => (value == null || value.isEmpty) ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: suffixIcon,
          border: const UnderlineInputBorder(),
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
      index: _selectedIndex,
      backgroundColor: Colors.transparent,
      color: Colors.black,
      height: 65,
      animationDuration: const Duration(milliseconds: 300),
      items: List.generate(icons.length, (i) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icons[i], color: _selectedIndex == i ? const Color(0xFF4997D0) : Colors.white, size: 24),
            if (_selectedIndex != i)
              Text(labels[i], style: const TextStyle(color: Colors.white, fontSize: 10)),
          ],
        );
      }),
      onTap: (index) {},
    );
  }
}

/// Formats user input as MM/YY (e.g. 1226 → 12/26)
class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    String formatted = '';
    if (text.length >= 3) {
      formatted = '${text.substring(0, 2)}/${text.substring(2)}';
    } else {
      formatted = text;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
