class OHLCData {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;

  OHLCData({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  factory OHLCData.fromJson(Map<String, dynamic> json) {
    return OHLCData(
      date: DateTime.fromMillisecondsSinceEpoch(json['t'] * 1000),
      open: json['o'].toDouble(),
      high: json['h'].toDouble(),
      low: json['l'].toDouble(),
      close: json['c'].toDouble(),
    );
  }
}
