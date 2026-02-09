import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- Imports (Ensure these match your project structure) ---
import 'candlestick_screen.dart';
import 'auth_service.dart';
import 'demo_trade_screen.dart';
import 'realtime_graph.dart';
import 'prediction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List companies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    final url = Uri.parse("http://127.0.0.1:8000/companies");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          companies = data['companies'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("API Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.value.currentUser;
    final String userName = user?.email?.split('@')[0] ?? "Trader";

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11), // Deep Obsidian
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.greenAccent),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Sleek Sliver App Bar
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: true,
                  pinned: true,
                  backgroundColor: const Color(0xFF161A1E),
                  elevation: 0,
                  flexibleSpace: const FlexibleSpaceBar(
                    titlePadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    title: Text(
                      "Market Pulse",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () async => await authService.value.signOut(),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),

                // 2. Welcome Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildPredictionCard(),
                      ],
                    ),
                  ),
                ),

                // 3. Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Market Watchlist",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "See All",
                            style: TextStyle(color: Colors.greenAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Optimized Stock List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildStockTile(companies[index]),
                      childCount: companies.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DemoTradeScreen(companies: companies),
          ),
        ),
        backgroundColor: const Color(0xFF00C087),
        elevation: 4,
        icon: const Icon(Icons.currency_exchange, color: Colors.black),
        label: const Text(
          "ENTER DEMO TRADE",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.15),
            Colors.blueAccent.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI ANALYSIS",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Predict market trends using our advanced LSTM models.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PredictionScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Run Forecast",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.psychology_outlined,
            size: 70,
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStockTile(dynamic company) {
    // Determine the actual market trend for the percentage text and price
    final String percentStr = company['percent_change']?.toString() ?? "";
    final bool isActuallyUp = !percentStr.contains('-');
    final Color trendColor = isActuallyUp
        ? const Color(0xFF00C087)
        : const Color(0xFFFF3B69);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2329),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CandlestickScreen(symbol: company['symbol']),
          ),
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              company['symbol'][0],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          company['name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              company['symbol'],
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(width: 8),
            Text(
              percentStr,
              style: TextStyle(
                color: trendColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- FIXED ICON 1: Candlestick (Always Red) ---
            IconButton(
              icon: const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFFFF3B69),
                size: 28,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CandlestickScreen(symbol: company['symbol']),
                ),
              ),
            ),
            const VerticalDivider(
              color: Colors.white10,
              indent: 15,
              endIndent: 15,
              width: 10,
            ),
            // --- FIXED ICON 2: Realtime Graph (Always Green) ---
            IconButton(
              icon: const Icon(
                Icons.insights_rounded,
                color: Color(0xFF00C087),
                size: 24,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RealtimeGraph(symbol: company['symbol']),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
