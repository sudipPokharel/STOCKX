import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class CandlestickScreen extends StatefulWidget {
  final String symbol;
  const CandlestickScreen({super.key, required this.symbol});

  @override
  State<CandlestickScreen> createState() => _CandlestickScreenState();
}

class _CandlestickScreenState extends State<CandlestickScreen> {
  List<CandleData> chartData = [];
  bool isLoading = true;

  late ZoomPanBehavior _zoomPanBehavior;
  late TrackballBehavior _trackballBehavior;

  double? openPrice, highPrice, lowPrice, closePrice, marketPrice;
  String? percentChange;

  @override
  void initState() {
    super.initState();

    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      zoomMode: ZoomMode.x,
      enableDoubleTapZooming: true,
    );

    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.groupAllPoints,
      lineType: TrackballLineType.vertical,
      lineDashArray: const [5, 5],
      lineColor: Colors.white38,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        color: Color(0xFF1E2329), // Modern dark tooltip
        textStyle: TextStyle(color: Colors.white, fontSize: 12),
        format:
            'point.x\nO: point.open\nH: point.high\nL: point.low\nC: point.close',
      ),
    );

    fetchData();
  }

  Future<void> fetchData() async {
    final candlestickUrl = Uri.parse(
      "http://127.0.0.1:8000/candlestick/${widget.symbol}",
    );
    final priceUrl = Uri.parse(
      "http://127.0.0.1:8000/company-info/${widget.symbol}",
    );

    try {
      final candleResp = await http.get(candlestickUrl);
      if (candleResp.statusCode == 200) {
        final data = json.decode(candleResp.body);
        final ohlc = data['ohlc'];

        chartData = ohlc.map<CandleData>((item) {
          final utcDate = DateTime.fromMillisecondsSinceEpoch(
            item['t'] * 1000,
            isUtc: true,
          );
          return CandleData(
            DateTime(utcDate.year, utcDate.month, utcDate.day),
            double.parse(item['o'].toString()),
            double.parse(item['h'].toString()),
            double.parse(item['l'].toString()),
            double.parse(item['c'].toString()),
          );
        }).toList();
      }

      final priceResp = await http.get(priceUrl);
      if (priceResp.statusCode == 200) {
        final data = json.decode(priceResp.body)['info'];
        setState(() {
          openPrice = data['open_price']?.toDouble();
          highPrice = data['high_price']?.toDouble();
          lowPrice = data['low_price']?.toDouble();
          closePrice = data['close_price']?.toDouble();
          marketPrice = data['market_price']?.toDouble();
          percentChange = data['percent_change'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUp = !(percentChange?.contains('-') ?? false);
    final Color trendColor = isUp
        ? const Color(0xFF00C087)
        : const Color(0xFFFF3B69);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11), // Pro Dark Background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : Column(
              children: [
                _buildModernHeader(trendColor, isUp),
                const Divider(color: Colors.white10, height: 1),
                _buildOHLCStats(),
                Expanded(child: _buildChart()),
                const SizedBox(height: 10),
              ],
            ),
    );
  }

  Widget _buildModernHeader(Color trendColor, bool isUp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "₹${marketPrice?.toStringAsFixed(2) ?? '0.00'}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Row(
                children: [
                  Text(
                    "${isUp ? '+' : ''}$percentChange",
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isUp ? Icons.trending_up : Icons.trending_down,
                    color: trendColor,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fullscreen, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildOHLCStats() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem("Open", openPrice),
          _statItem("High", highPrice),
          _statItem("Low", lowPrice),
          _statItem("Close", closePrice),
        ],
      ),
    );
  }

  Widget _statItem(String label, double? value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value?.toStringAsFixed(1) ?? '-',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      zoomPanBehavior: _zoomPanBehavior,
      trackballBehavior: _trackballBehavior,
      primaryXAxis: DateTimeAxis(
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        dateFormat: DateFormat('MMM dd'),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true, // Industry Standard: Price on Right
        majorGridLines: const MajorGridLines(
          color: Colors.white10,
          dashArray: [5, 5],
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
        numberFormat: NumberFormat.compact(),
      ),
      series: <CandleSeries>[
        CandleSeries<CandleData, DateTime>(
          dataSource: chartData,
          bearColor: const Color(0xFFFF3B69), // Professional Rose
          bullColor: const Color(0xFF00C087), // Professional Emerald
          enableSolidCandles: true,
          xValueMapper: (CandleData data, _) => data.x,
          lowValueMapper: (CandleData data, _) => data.low,
          highValueMapper: (CandleData data, _) => data.high,
          openValueMapper: (CandleData data, _) => data.open,
          closeValueMapper: (CandleData data, _) => data.close,
        ),
      ],
    );
  }
}

class CandleData {
  final DateTime x;
  final double open, high, low, close;
  CandleData(this.x, this.open, this.high, this.low, this.close);
}
