class TimeSlot {
  final String start;
  final String end;
  final String display;
  final int duration;

  TimeSlot({
    required this.start,
    required this.end,
    required this.display,
    required this.duration,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    try {
      // Handle potential null or invalid values
      String start = '';
      String end = '';
      String display = '';
      int duration = 60;

      // Parse start time
      if (json['start'] != null) {
        start = json['start'].toString();
        // Ensure proper HH:mm format
        if (start.contains(':')) {
          final parts = start.split(':');
          if (parts.length >= 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            start = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          }
        }
      }

      // Parse end time
      if (json['end'] != null) {
        end = json['end'].toString();
        // Ensure proper HH:mm format
        if (end.contains(':')) {
          final parts = end.split(':');
          if (parts.length >= 2) {
            final hour = int.tryParse(parts[0]) ?? 0;
            final minute = int.tryParse(parts[1]) ?? 0;
            end = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
          }
        }
      }

      // Parse display - clean up any malformed text like "60h"
      if (json['display'] != null) {
        display = json['display'].toString();
        // Remove any "60h", "60min", or similar malformed text
        display = display.replaceAll(RegExp(r'\d+h|60h|60min|60\s*min'), '');
        display = display.trim();
        // If display is empty after cleaning, generate a proper one
        if (display.isEmpty) {
          display = '$start-$end';
        }
      } else {
        // Generate display if not provided
        display = '$start-$end';
      }

      // Parse duration
      if (json['duration'] != null) {
        duration = int.tryParse(json['duration'].toString()) ?? 60;
      }

      // Final validation - ensure display is clean
      if (display.contains('60h') || display.contains('60min') || display.contains('60 min')) {
        display = '$start-$end';
      }

      return TimeSlot(
        start: start,
        end: end,
        display: display,
        duration: duration,
      );
    } catch (e) {
      // Return a default TimeSlot if parsing fails
      print('Error parsing TimeSlot from JSON: $e');
      print('JSON data: $json');
      return TimeSlot(
        start: '00:00',
        end: '01:00',
        display: '00:00-01:00',
        duration: 60,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'display': display,
      'duration': duration,
    };
  }
}
