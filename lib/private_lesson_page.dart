import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrivateLessonPage extends StatefulWidget {
  const PrivateLessonPage({super.key});

  @override
  State<PrivateLessonPage> createState() => _PrivateLessonPageState();
}

class _PrivateLessonPageState extends State<PrivateLessonPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Map<String, String>> classes = [
    {
      "title": "C1 Group",
      "desc": "Enjoy pickleball with friends and family.",
      "date": "RM 350",
      "month": "10 Classes",
      "image": "assets/images/event1.svg",
    },
    {
      "title": "South Key class",
      "desc": "Fun session with coach. Great for all levels.",
      "date": "RM 280",
      "month": "8 Classes",
      "image": "assets/images/event4.svg",
    },
    {
      "title": "Kids Coaching",
      "desc": "Tailored coaching for kids. Safe and fun!",
      "date": "RM 150",
      "month": "Per Class",
      "image": "assets/images/event3.svg",
    },
    {
      "title": "Master Hoo Class",
      "desc": "Advance skills with Master Hoo.",
      "date": "RM 400",
      "month": "12 Classes",
      "image": "assets/images/event2.svg",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildClassCard(Map<String, String> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SvgPicture.asset(
                  data['image']!,
                  width: double.infinity,
                  height: 120,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(data['date']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(data['month']!,
                          style: const TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content + Button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(data['desc']!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),

                  // Coach info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 35,
                        height: 35,
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: SvgPicture.asset(
                          'assets/icons/avatar.svg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Coach by:\nMdm Halima",
                          style: TextStyle(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),

                  const Spacer(),

                  // Register Now button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Booking action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Color(0xFF4997D0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Register Now",
                          style: TextStyle(fontSize: 13),
                          textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FBFD),
        appBar: AppBar(
          title: const Text(
            "Personal Coaching",
            style: TextStyle(
              color: Color(0xFF0C0509),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/coaching');
            },
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFFA5ADB1),
                  borderRadius: BorderRadius.circular(5),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                tabs: const [
                  Tab(text: "UPCOMING"),
                  Tab(text: "Your Booking"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // UPCOMING TAB
            Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                itemCount: classes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 18,
                  childAspectRatio: 0.58,
                ),
                itemBuilder: (context, index) =>
                    _buildClassCard(classes[index]),
              ),
            ),

            // YOUR BOOKING TAB
            const Center(child: Text("No bookings yet")),
          ],
        ),
      ),
    );
  }
}
