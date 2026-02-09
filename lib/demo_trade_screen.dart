import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DemoTradeScreen extends StatefulWidget {
  final List companies;

  const DemoTradeScreen({super.key, required this.companies});

  @override
  State<DemoTradeScreen> createState() => _DemoTradeScreenState();
}

class _DemoTradeScreenState extends State<DemoTradeScreen> {
  static const Color primaryBg = Color(0xFF0B101B);
  static const Color secondaryBg = Color(0xFF161C2D);
  static const Color accentBlue = Color(0xFF0091FF);
  static const Color sellRed = Color(0xFFE53935);
  static const Color buyGreen = Color(0xFF43A047);

  double balance = 1000000.00;
  double investment = 50.0;

  // High-frequency price data
  List<FlSpot> priceSpots = [const FlSpot(0, 1.184500)];
  double currentPrice = 1.184500;
  Timer? marketTimer;
  double tickIndex = 1.0;

  // Active Trade State
  bool isTradeActive = false;
  double entryPrice = 0;
  String tradeType = "";
  int remainingSeconds = 20;

  // Live P/L calculation based on direction
  double get livePL {
    if (!isTradeActive) return 0.0;
    bool isWinning = tradeType == "BUY"
        ? currentPrice > entryPrice
        : currentPrice < entryPrice;
    return isWinning ? (investment * 0.86) : -investment;
  }

  @override
  void initState() {
    super.initState();
    _startFluidMarket();
  }

  void _startFluidMarket() {
    // Faster timer (200ms) creates the "jittery" movement seen in the video
    marketTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      setState(() {
        // Precise micro-movements
        double volatility = 0.000015;
        double change = (Random().nextDouble() - 0.5) * volatility;
        currentPrice += change;

        tickIndex += 0.2; // Move the X-axis forward
        priceSpots.add(FlSpot(tickIndex, currentPrice));

        if (priceSpots.length > 60) priceSpots.removeAt(0);

        // Every 5 ticks (1 second), update the trade countdown
        if (t.tick % 5 == 0 && isTradeActive) {
          remainingSeconds--;
          if (remainingSeconds <= 0) _resolveTrade();
        }
      });
    });
  }

  void _placeTrade(String type) {
    if (investment > balance) return;
    setState(() {
      isTradeActive = true;
      tradeType = type;
      entryPrice = currentPrice;
      remainingSeconds = 20;
      balance -= investment;
    });
  }

  void _resolveTrade({bool earlyExit = false}) {
    if (!isTradeActive) return;

    double payout = 0;
    if (earlyExit) {
      // Return investment + a small portion of P/L for early exit
      payout = investment + (livePL * 0.4);
    } else {
      bool win = tradeType == "BUY"
          ? currentPrice > entryPrice
          : currentPrice < entryPrice;
      payout = win ? investment * 1.86 : 0;
    }

    setState(() {
      balance += payout;
      isTradeActive = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildChartArea()),
          _buildControlPanel(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: secondaryBg,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _statCol("₹${balance.toStringAsFixed(2)}", "Balance", Colors.orange),
          const SizedBox(width: 40),
          _statCol(
            "₹${livePL.toStringAsFixed(2)}",
            "Live P/L",
            livePL >= 0 ? buyGreen : sellRed,
          ),
        ],
      ),
    );
  }

  Widget _statCol(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildChartArea() {
    return Stack(
      children: [
        LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) =>
                  FlLine(color: Colors.white.withOpacity(0.05)),
            ),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: priceSpots,
                isCurved:
                    true, // This creates the smooth "wave" look from the video
                curveSmoothness: 0.1,
                color: accentBlue,
                barWidth: 2,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [accentBlue.withOpacity(0.2), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: isTradeActive
                  ? [
                      HorizontalLine(
                        y: entryPrice,
                        color: tradeType == "BUY" ? buyGreen : sellRed,
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          labelResolver: (_) => " ENTRY",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ]
                  : [],
            ),
          ),
        ),
        // Live Price Label on the Y-Axis
        Positioned(
          right: 0,
          top: 150, // Simplified for UI positioning
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: accentBlue,
            child: Text(
              currentPrice.toStringAsFixed(6),
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ),
        if (isTradeActive)
          Positioned(
            top: 20,
            left: 20,
            child: _badge("EXPIRES IN: ${remainingSeconds}s", Colors.amber),
          ),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: secondaryBg,
      child: Column(
        children: [
          Row(
            children: [
              _inputBox(
                "Investment",
                "₹${investment.toStringAsFixed(0)}",
                onTap: _showInvestmentSheet,
              ),
              const SizedBox(width: 10),
              _inputBox("Duration", "20 Sec", onTap: null),
            ],
          ),
          const SizedBox(height: 16),
          isTradeActive
              ? _actionBtn(
                  "CLOSE EARLY",
                  Colors.white24,
                  () => _resolveTrade(earlyExit: true),
                )
              : Row(
                  children: [
                    Expanded(
                      child: _actionBtn(
                        "SELL",
                        sellRed,
                        () => _placeTrade("SELL"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _actionBtn(
                        "BUY",
                        buyGreen,
                        () => _placeTrade("BUY"),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _inputBox(String label, String val, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: primaryBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
              Text(
                val,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showInvestmentSheet() {
    TextEditingController c = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: secondaryBg,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Enter Amount",
                labelStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 20),
            _actionBtn("CONFIRM", accentBlue, () {
              double? v = double.tryParse(c.text);
              if (v != null && v <= balance) setState(() => investment = v);
              Navigator.pop(context);
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
