import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'bookingdetails.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({Key? key}) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String selectedDuration = "1 hour";
  String selectedCourt = "";

  final List<String> durations = ["1 hour", "2 hours", "3 hours"];

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCourt(String label, {bool available = true}) {
    final bool isSelected = selectedCourt == label;
    final Color bgColor = isSelected ? Colors.black : available ? const Color(0xFF4997D0) : Colors.grey.shade300;
    final Color textColor = isSelected || available ? Colors.white : Colors.black54;

    return GestureDetector(
      onTap: available ? () => setState(() => selectedCourt = label) : null,
      child: Container(
        alignment: Alignment.center,
        height: 50,
        margin: const EdgeInsets.all(2),
        color: bgColor,
        child: Text(label, style: TextStyle(color: textColor, fontSize: 13)),
      ),
    );
  }

  Widget _buildStaticBox(String label) {
    return Container(
      alignment: Alignment.center,
      height: 160,
      margin: const EdgeInsets.all(2),
      color: const Color(0xFF4997D0),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCourtGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegend(const Color(0xFF4997D0), "Available"),
            const SizedBox(width: 12),
            _buildLegend(Colors.grey.shade300, "Not Available"),
            const SizedBox(width: 12),
            _buildLegend(Colors.black, "Selected"),
          ],
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _buildCourt("Court 9")),
          Expanded(child: _buildCourt("Court 6")),
          Expanded(child: _buildCourt("Court 11")),
        ]),
        Row(children: [
          Expanded(child: _buildCourt("Court 8", available: false)),
          Expanded(child: _buildCourt("Court 5")),
          Expanded(child: _buildCourt("Court 10")),
        ]),
        Row(children: [
          Expanded(child: _buildCourt("Court 7", available: false)),
          Expanded(child: _buildCourt("Court 4")),
          const Expanded(child: SizedBox()),
        ]),
        Row(children: [
          Expanded(flex: 1, child: _buildStaticBox("Event Space")),
          Expanded(flex: 1, child: Column(
            children: [
              _buildCourt("Court 3", available: false),
              _buildCourt("Court 2"),
              _buildCourt("Court 1"),
            ],
          )),
          const Expanded(child: SizedBox()),
        ]),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF534F53),
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text("Reception", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationButton(String label) {
    final bool isSelected = selectedDuration == label;

    return GestureDetector(
      onTap: () {
        setState(() => selectedDuration = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4997D0) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF4997D0) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check, color: Colors.white, size: 16),
            if (isSelected) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          bool isSelected = date.day == selectedDate.day &&
              date.month == selectedDate.month &&
              date.year == selectedDate.year;

          return GestureDetector(
            onTap: () => setState(() => selectedDate = date),
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4997D0) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('E').format(date), style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text('${date.day}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(DateFormat('MMM').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔙 Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),

              // 🔶 Banner
              SvgPicture.asset('assets/images/orderbanner.svg', width: double.infinity, height: 140, fit: BoxFit.fitWidth),

              const Text("Select Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              _buildDateSelector(),
              const SizedBox(height: 20),
              const Text("Select Time & Duration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(selectedTime.format(context), style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: durations
                            .map((d) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildDurationButton(d),
                        ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Select Court", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              _buildCourtGrid(),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BookingDetailsPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4997D0),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: const Text("Book Now", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
