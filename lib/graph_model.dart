class PricePoint {
  final DateTime time;
  final double price;

  PricePoint({required this.time, required this.price});

  factory PricePoint.fromJson(Map<String, dynamic> json) {
    return PricePoint(
      time: DateTime.fromMillisecondsSinceEpoch(json['t'] * 1000),
      price: json['c'].toDouble(),
    );
  }
}
