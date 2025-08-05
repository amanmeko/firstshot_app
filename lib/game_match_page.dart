// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// import 'booking_page.dart';
// import 'coaching_select.dart';
// import 'main_page.dart';
// import 'instructors_page.dart';
// import 'settings_page.dart';

// class GameMatchPage extends StatefulWidget {
//   const GameMatchPage({super.key});

//   @override
//   State<GameMatchPage> createState() => _GameMatchPageState();
// }

// class _GameMatchPageState extends State<GameMatchPage> {
//   int _selectedIndex = 3;

//   final List<String> _labels = ['Booking', 'Lessons', 'Home', 'Instructors', 'Settings'];
//   final List<IconData> _icons = [
//     Icons.calendar_today,
//     Icons.assignment,
//     Icons.home,
//     Icons.sports_tennis_rounded,
//     Icons.settings,
//   ];

//   final List<Widget> _pages = [
//     const BookingPage(),
//     const CoachingSelect(),
//     const HomePage(),
//     const GameMatchPage(),
//     const SettingsPage(),
//   ];

//   final matches = [
//     {
//       'date': '12.12.2025',
//       'time': '1.00pm',
//       'available': 1,
//       'players': [
//         {'name': 'Karim\n(Host)', 'image': 'assets/icons/avatar.svg'},
//         {'name': 'Abdul Ahmad', 'image': 'assets/icons/avatar.svg'},
//         null,
//         {'name': 'Siti Klang', 'image': 'assets/icons/avatar.svg'},
//       ]
//     },
//   ];

//   void _onBottomTap(int index) {
//     if (index == _selectedIndex) return;
//     Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => _pages[index]));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FBFD),
//       bottomNavigationBar: CurvedNavigationBar(
//         index: _selectedIndex,
//         backgroundColor: Colors.transparent,
//         color: Colors.black,
//         height: 65,
//         animationDuration: const Duration(milliseconds: 300),
//         items: List.generate(_icons.length, (index) {
//           return Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 _icons[index],
//                 color: _selectedIndex == index ? Colors.white : Colors.white,
//                 size: 24,
//               ),
//               if (_selectedIndex != index)
//                 Text(_labels[index], style: const TextStyle(color: Colors.white, fontSize: 10)),
//             ],
//           );
//         }),
//         onTap: _onBottomTap,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.only(bottom: 100),
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.arrow_back),
//                       onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
//                     ),
//                     const SizedBox(width: 8),
//                     const Text("Pickleball Match", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//               ),
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: matches.length,
//                 itemBuilder: (context, index) => _buildMatchCard(matches[index]),
//               ),
//               const SizedBox(height: 16),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: ElevatedButton(
//                   onPressed: () {
//                     showDialog(
//                       context: context,
//                       barrierDismissible: false,
//                       builder: (context) => _buildBookingPopup(context),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF60B4E0),
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     minimumSize: const Size.fromHeight(50),
//                   ),
//                   child: const Text("Create New Match Request", style: TextStyle(color: Colors.white)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMatchCard(Map match) {
//     final players = match['players'];

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.8),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
//       ),
//       padding: const EdgeInsets.all(8),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.black,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _infoWithIcon("Date:", match['date']),
//                 _infoWithIcon("Time:", match['time']),
//                 _infoWithIcon("Available Slot:", "${match['available']}"),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//           Stack(
//             alignment: Alignment.center,
//             children: [
//               SvgPicture.asset(
//                 'assets/icons/x2.svg',
//                 width: double.infinity,
//                 height: 120,
//                 fit: BoxFit.contain,
//               ),
//               Positioned.fill(
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: players.map<Widget>((player) {
//                     if (player == null) {
//                       return GestureDetector(
//                         onTap: () => print("Join Match"),
//                         child: Column(
//                           children: [
//                             Container(
//                               width: 48,
//                               height: 48,
//                               decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
//                               padding: const EdgeInsets.all(8),
//                               child: SvgPicture.asset('assets/icons/plus.svg'),
//                             ),
//                             const SizedBox(height: 4),
//                             const Text("Click to Join", style: TextStyle(fontSize: 12, color: Colors.black)),
//                           ],
//                         ),
//                       );
//                     }
//                     return Column(
//                       children: [
//                         Container(
//                           width: 48,
//                           height: 48,
//                           decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
//                           padding: const EdgeInsets.all(4),
//                           child: SvgPicture.asset(player['image']),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           player['name'],
//                           style: const TextStyle(fontSize: 12, color: Colors.black),
//                           textAlign: TextAlign.center,
//                         ),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _infoWithIcon(String label, String value) {
//     return Row(
//       children: [
//         Image.asset('assets/icons/racketball.png', height: 16),
//         const SizedBox(width: 4),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
//             Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildBookingPopup(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//       backgroundColor: Colors.white,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Align(
//               alignment: Alignment.topRight,
//               child: GestureDetector(
//                 onTap: () => Navigator.pop(context),
//                 child: Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade300),
//                   child: const Icon(Icons.close, size: 20),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Select your booking to create\nGame Match Making',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.blue.shade900),
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               padding: const EdgeInsets.all(12),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: const [
//                         Text("Booking : FS00001"),
//                         Text("Court : 1"),
//                         Text("Date / Time : 12.12.2026 . 5pm"),
//                       ],
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                       Navigator.pushNamed(context, '/gamematchset');
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.blue,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                     ),
//                     child: const Text("Select", style: TextStyle(color: Colors.white)),
//                   )
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               children: const [
//                 Expanded(child: Divider(thickness: 1)),
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 8),
//                   child: Text("or"),
//                 ),
//                 Expanded(child: Divider(thickness: 1)),
//               ],
//             ),
//             const SizedBox(height: 16),
//             OutlinedButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pushNamed(context, '/booking');
//               },
//               style: OutlinedButton.styleFrom(
//                 side: BorderSide(color: Colors.blue.shade900),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//               child: const Text("Book Court Now", style: TextStyle(fontWeight: FontWeight.bold)),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
