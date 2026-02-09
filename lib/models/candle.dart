class Candle {
  final DateTime date;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  Candle({
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory Candle.fromJson(Map<String, dynamic> json, int index) {
    return Candle(
      date: DateTime.fromMillisecondsSinceEpoch(json['t'][index] * 1000),
      open: (json['o'][index] as num).toDouble(),
      high: (json['h'][index] as num).toDouble(),
      low: (json['l'][index] as num).toDouble(),
      close: (json['c'][index] as num).toDouble(),
      volume: (json['v'][index] as num).toDouble(),
    );
  }
}
