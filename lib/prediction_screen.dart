import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Model for price points
class PricePoint {
  final DateTime time;
  final double price;
  PricePoint({required this.time, required this.price});
}

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  List<PricePoint> prices = [];
  bool loading = true;
  String errorMessage = '';

  // Tomorrow predicted price info
  String date = '';
  double? predictedPrice;

  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();

    // Enable zooming and panning
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      zoomMode: ZoomMode.xy,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: true, // for desktop
    );

    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      // Fetch historical OHLC (closing prices)
      final ohlcUrl = Uri.parse("http://127.0.0.1:8000/candlestick/SAHAS");
      final ohlcResponse = await http.get(ohlcUrl);

      if (ohlcResponse.statusCode != 200) {
        setState(() {
          errorMessage = 'Failed to load historical data';
          loading = false;
        });
        return;
      }

      final ohlcData = json.decode(ohlcResponse.body);
      List<PricePoint> tempPrices = [];
      if (ohlcData['status'] == 'success') {
        for (var item in ohlcData['ohlc']) {
          tempPrices.add(
            PricePoint(
              time: DateTime.fromMillisecondsSinceEpoch(item['t'] * 1000),
              price: (item['c'] as num).toDouble(), // only closing price
            ),
          );
        }
      }

      // Fetch tomorrow's prediction
      final predictUrl = Uri.parse("http://127.0.0.1:8000/predict/sahas");
      final predictResponse = await http.get(predictUrl);

      if (predictResponse.statusCode == 200) {
        final data = json.decode(predictResponse.body);
        if (data['status'] == 'success') {
          predictedPrice = (data['predicted_price'] as num).toDouble();
          date = data['date'];

          // Add tomorrow's predicted closing price as last point
          tempPrices.add(
            PricePoint(time: DateTime.parse(date), price: predictedPrice!),
          );
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Prediction failed';
            loading = false;
          });
          return;
        }
      }

      setState(() {
        prices = tempPrices;
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("SAHAS Prediction"),
        backgroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : Column(
              children: [
                const SizedBox(height: 10),
                if (predictedPrice != null)
                  Text(
                    "Predicted Closing Price will be: Rs. $predictedPrice",
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: SfCartesianChart(
                    zoomPanBehavior: _zoomPanBehavior,
                    primaryXAxis: DateTimeAxis(),
                    primaryYAxis: NumericAxis(),
                    series: <LineSeries<PricePoint, DateTime>>[
                      LineSeries<PricePoint, DateTime>(
                        dataSource: prices,
                        xValueMapper: (p, _) => p.time,
                        yValueMapper: (p, _) => p.price,
                        width: 2,
                        color: Colors.blue,
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
