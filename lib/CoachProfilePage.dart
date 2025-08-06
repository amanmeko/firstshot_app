import 'package:flutter/material.dart';
import 'instructors_page.dart';

class CoachProfilePage extends StatelessWidget {
  const CoachProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Coach coach = ModalRoute.of(context)!.settings.arguments as Coach;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      appBar: AppBar(
        title: Text('${coach.name}\'s Profile'),
        backgroundColor: const Color(0xFF4997D0),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: coach.avatarUrl != null
                    ? NetworkImage(coach.avatarUrl!)
                    : null,
                onBackgroundImageError: coach.avatarUrl != null
                    ? (error, stackTrace) => print('Image load error for ${coach.name}: ${coach.avatarUrl} - Error: $error')
                    : null,
                child: coach.avatarUrl == null || coach.avatarUrl!.isEmpty
                    ? Text(
                        coach.name.isNotEmpty ? coach.name[0].toUpperCase() : 'C',
                        style: const TextStyle(fontSize: 32, color: Colors.black54),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                coach.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                coach.coachingType,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text('Level: ${coach.level ?? 'N/A'}'),
              Text('DUPR ID: ${coach.duprId ?? 'N/A'}'),
              Text('Experience: ${coach.experiences ?? 'N/A'}'),
              Text('Contact: ${coach.mobileNo ?? 'N/A'}'),
              const SizedBox(height: 16),
              const Text(
                'Courses:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: coach.courses.length,
                  itemBuilder: (context, index) {
                    final course = coach.courses[index];
                    return ListTile(
                      title: Text(course.name),
                      subtitle: Text('Type: ${course.type} | Duration: ${course.duration} | Price: RM ${course.price.toStringAsFixed(2)}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}