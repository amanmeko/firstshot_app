import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CoachingSelect extends StatefulWidget {
  const CoachingSelect({super.key});

  @override
  State<CoachingSelect> createState() => _CoachingSelectState();
}

class _CoachingSelectState extends State<CoachingSelect> {
  double _scaleGroup = 1.0;
  double _scalePrivate = 1.0;

  void _onTap(String route) {
    Future.delayed(const Duration(milliseconds: 100), () {
      Navigator.pushNamed(context, route);
    });
  }

  void _animateScale(String key, double value) {
    setState(() {
      if (key == 'group') {
        _scaleGroup = value;
      } else {
        _scalePrivate = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔙 Back Button (go to Home Page)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
              ),
              const SizedBox(height: 16),

              // 📝 Title
              const Center(
                child: Text(
                  "Choose your\nCoaching Program",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 5),

              // ⬇️ Arrow SVG
              Center(
                child: SvgPicture.asset(
                  'assets/icons/x.svg',
                  height: 100,
                ),
              ),
              const SizedBox(height: 22),

              // 🎯 Group Lesson Button
              AnimatedScale(
                scale: _scaleGroup,
                duration: const Duration(milliseconds: 150),
                child: GestureDetector(
                  onTapDown: (_) => _animateScale('group', 0.95),
                  onTapUp: (_) {
                    _animateScale('group', 1.0);
                    _onTap('/groupclass');
                  },
                  onTapCancel: () => _animateScale('group', 1.0),
                  child: _buildLessonButton(
                    title: "Group Lesson",
                    svgPath: 'assets/images/group.svg',
                    bgColor: const Color(0xFF41A0DD),
                    svgSize: 160,
                    imageLeft: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🎯 Private Lesson Button
              AnimatedScale(
                scale: _scalePrivate,
                duration: const Duration(milliseconds: 150),
                child: GestureDetector(
                  onTapDown: (_) => _animateScale('private', 0.95),
                  onTapUp: (_) {
                    _animateScale('private', 1.0);
                    _onTap('/private-lesson');
                  },
                  onTapCancel: () => _animateScale('private', 1.0),
                  child: _buildLessonButton(
                    title: "Private Lesson",
                    svgPath: 'assets/images/private.svg',
                    bgColor: const Color(0xFF7E9197),
                    svgSize: 150,
                    imageLeft: false,
                  ),
                ),
              ),
              const Spacer(),

              // 🔻 Footer
              const Center(
                child: Text(
                  "© Copyrighted by First Shot Sdn Bhd with ❤️",
                  style: TextStyle(fontSize: 12, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLessonButton({
    required String title,
    required String svgPath,
    required Color bgColor,
    required double svgSize,
    required bool imageLeft,
  }) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: bgColor),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: imageLeft
            ? [_svgImage(svgPath, svgSize), _lessonText(title)]
            : [_lessonText(title), _svgImage(svgPath, svgSize)],
      ),
    );
  }

  Widget _svgImage(String path, double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(2),
      child: SvgPicture.asset(
        path,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _lessonText(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}
