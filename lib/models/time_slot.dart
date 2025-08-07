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
    return TimeSlot(
      start: json['start'],
      end: json['end'],
      display: json['display'],
      duration: json['duration'],
    );
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
