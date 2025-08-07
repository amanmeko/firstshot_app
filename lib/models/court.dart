class Court {
  final int id;
  final String name;
  final double price;
  final List<String> operationHours;

  Court({
    required this.id,
    required this.name,
    required this.price,
    required this.operationHours,
  });

  factory Court.fromJson(Map<String, dynamic> json) {
    return Court(
      id: json['id'],
      name: json['name'],
      price: double.parse(json['price'].toString()),
      operationHours: List<String>.from(json['operation_hours'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'operation_hours': operationHours,
    };
  }
}
