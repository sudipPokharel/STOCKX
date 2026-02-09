class ChartData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;

  ChartData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] * 1000),
      open: (json['open'] as num).toDouble(),
      high: (json['high'] as num).toDouble(),
      low: (json['low'] as num).toDouble(),
      close: (json['close'] as num).toDouble(),
    );
  }
}
