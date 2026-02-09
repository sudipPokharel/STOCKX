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

  double? openPrice, highPrice, lowPrice;
  double? prevClosePrice; // previous day's close
  double? marketPrice; // current price

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
      lineType: TrackballLineType.vertical,
      lineDashArray: const [5, 5],
      lineColor: Colors.white54,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        color: Color(0xFF1E2329),
        textStyle: TextStyle(color: Colors.white),
        decimalPlaces: 2,
        format:
            'point.x\nO: point.open\nH: point.high\nL: point.low\nC: point.close',
      ),
    );

    fetchData();
  }

  // ✅ Correct percentage calculation
  double getPercentChange() {
    if (prevClosePrice == null || marketPrice == null || prevClosePrice == 0) {
      return 0;
    }
    return ((marketPrice! - prevClosePrice!) / prevClosePrice!) * 100;
  }

  Future<void> fetchData() async {
    final candlestickUrl = Uri.parse(
      "http://127.0.0.1:8000/candlestick/${widget.symbol}",
    );
    final priceUrl = Uri.parse(
      "http://127.0.0.1:8000/company-info/${widget.symbol}",
    );

    try {
      // Fetch OHLC chart data
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

      // Fetch live prices and OHLC stats
      final priceResp = await http.get(priceUrl);
      if (priceResp.statusCode == 200) {
        final data = json.decode(priceResp.body)['info'];

        setState(() {
          openPrice = data['open_price']?.toDouble();
          highPrice = data['high_price']?.toDouble();
          lowPrice = data['low_price']?.toDouble();

          // Use previous close from API, fallback to close_price
          prevClosePrice =
              data['prev_close_price']?.toDouble() ??
              data['close_price']?.toDouble();

          // Use market price if available, else fallback to close price
          marketPrice =
              data['market_price']?.toDouble() ??
              data['close_price']?.toDouble();

          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = getPercentChange();
    final isPositive = pct >= 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : Column(
              children: [
                _buildPriceHeader(isPositive, pct),
                const Divider(color: Colors.white12, height: 1),
                _buildOHLCStats(),
                const SizedBox(height: 10),
                Expanded(child: _buildChart()),
              ],
            ),
    );
  }

  Widget _buildPriceHeader(bool isPositive, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                "${isPositive ? '+' : ''}${pct.toStringAsFixed(2)}%",
                style: TextStyle(
                  color: isPositive
                      ? const Color(0xFF00C087)
                      : const Color(0xFFFF3B69),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
          _statItem("High", highPrice),
          _statItem("Low", lowPrice),
          _statItem("Open", openPrice),
          _statItem("Prev. Close", prevClosePrice),
        ],
      ),
    );
  }

  Widget _statItem(String label, double? value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value?.toStringAsFixed(2) ?? '-',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
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
        opposedPosition: true,
        majorGridLines: const MajorGridLines(color: Colors.white10),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
      ),
      series: <CandleSeries>[
        CandleSeries<CandleData, DateTime>(
          dataSource: chartData,
          bearColor: const Color(0xFFFF3B69),
          bullColor: const Color(0xFF00C087),
          enableSolidCandles: true,
          xValueMapper: (d, _) => d.x,
          lowValueMapper: (d, _) => d.low,
          highValueMapper: (d, _) => d.high,
          openValueMapper: (d, _) => d.open,
          closeValueMapper: (d, _) => d.close,
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
