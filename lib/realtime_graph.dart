import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'graph_model.dart';

class RealtimeGraph extends StatefulWidget {
  final String symbol;

  const RealtimeGraph({super.key, required this.symbol});

  @override
  State<RealtimeGraph> createState() => _RealtimeGraphState();
}

class _RealtimeGraphState extends State<RealtimeGraph> {
  List<PricePoint> prices = [];
  Timer? timer;

  double? openPrice, highPrice, lowPrice, closePrice, marketPrice;
  String? percentChange;

  @override
  void initState() {
    super.initState();
    loadGraph();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => loadGraph());
  }

  Future<void> loadGraph() async {
    try {
      final data = await ApiService.getLineGraphData(widget.symbol);
      final info = await ApiService.getCompanyInfo(widget.symbol);

      setState(() {
        prices = data;
        openPrice = info['open_price']?.toDouble();
        highPrice = info['high_price']?.toDouble();
        lowPrice = info['low_price']?.toDouble();
        closePrice = info['close_price']?.toDouble();
        marketPrice = info['market_price']?.toDouble();
        percentChange = info['percent_change'];
      });
    } catch (e) {
      debugPrint("Error loading graph: $e");
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if the trend is up or down
    final bool isUp = !(percentChange?.contains('-') ?? false);
    final Color trendColor = isUp
        ? const Color(0xFF00C087)
        : const Color(0xFFFF3B69);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          widget.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: prices.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : Column(
              children: [
                _buildLivePriceHeader(trendColor, isUp),
                const SizedBox(height: 20),
                Expanded(child: _buildChart(trendColor)),
                _buildStatsGrid(),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildLivePriceHeader(Color trendColor, bool isUp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Row(
                children: [
                  Icon(
                    isUp ? Icons.trending_up : Icons.trending_down,
                    color: trendColor,
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "${isUp ? '+' : ''}$percentChange",
                    style: TextStyle(
                      color: trendColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: trendColor.withOpacity(0.2)),
            ),
            child: Text(
              "LIVE",
              style: TextStyle(
                color: trendColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Color trendColor) {
    return SfCartesianChart(
      margin: EdgeInsets.zero,
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        isVisible: true,
        majorGridLines: const MajorGridLines(width: 0),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        opposedPosition: true,
        isVisible: true,
        majorGridLines: const MajorGridLines(
          color: Colors.white10,
          dashArray: [5, 5],
        ),
        axisLine: const AxisLine(width: 0),
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 10),
        numberFormat: NumberFormat.simpleCurrency(name: '₹', decimalDigits: 0),
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        tooltipSettings: const InteractiveTooltip(
          enable: true,
          color: Color(0xFF1E2329),
        ),
        lineType: TrackballLineType.vertical,
        lineDashArray: const [5, 5],
      ),
      series: <AreaSeries<PricePoint, DateTime>>[
        AreaSeries<PricePoint, DateTime>(
          dataSource: prices,
          xValueMapper: (p, _) => p.time,
          yValueMapper: (p, _) => p.price,
          borderColor: trendColor,
          borderWidth: 2,
          gradient: LinearGradient(
            colors: [trendColor.withOpacity(0.3), trendColor.withOpacity(0.0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          animationDuration: 1000,
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161A1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem("Open", openPrice),
              _statItem("Prev. Close", closePrice),
            ],
          ),
          const Divider(height: 30, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem("Day High", highPrice, color: const Color(0xFF00C087)),
              _statItem("Day Low", lowPrice, color: const Color(0xFFFF3B69)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, double? value, {Color color = Colors.white}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value?.toStringAsFixed(2) ?? "-",
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
