import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ohlc_model.dart';
import 'graph_model.dart';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  // ---------------- EXISTING (UNCHANGED) ----------------
  static Future<List<OHLCData>> getOHLC(String symbol) async {
    final response = await http.get(Uri.parse("$baseUrl/ohlc/$symbol"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      return data.map((e) => OHLCData.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load OHLC data");
    }
  }

  // ---------------- ADDED FOR NORMAL GRAPH ----------------
  static Future<List<PricePoint>> getLineGraphData(String symbol) async {
    final response = await http.get(Uri.parse("$baseUrl/candlestick/$symbol"));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List list = body['ohlc'];

      return list.map((e) => PricePoint.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load graph data");
    }
  }

  // ---------------- ADDED FOR LIVE OHLC INFO ----------------
  static Future<Map<String, dynamic>> getCompanyInfo(String symbol) async {
    final response = await http.get(Uri.parse("$baseUrl/company-info/$symbol"));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['info'];
    } else {
      throw Exception("Failed to load company info");
    }
  }
}
