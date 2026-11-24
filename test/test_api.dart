import 'dart:convert';
import 'package:http/http.dart' as http;

// ignore_for_file: avoid_print
void main() async {
  print("Testing json parsing directly...");
  final response = await http.post(
    Uri.parse("http://138.197.116.81:50008"),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'getSignaturesForAddress',
      'params': ['8evPjjozSHNcoGRcv7zzxwan9sf3ubJ8q9CFzms6AK97', {'limit': 5}],
    }),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final result = data['result'];
    if (result != null && result is List) {
      print("Got ${result.length} items.");
      for (var item in result) {
         try {
           final sig = item['signature'] ?? '';
           final amountXrs = (item['amount_xrs'] ?? 0).toDouble();
           print("Successfully parsed tx $sig : $amountXrs XRS");
         } catch (e) {
           print("Failed to parse item: $e");
         }
      }
    }
  } else {
    print("HTTP ${response.statusCode}");
  }
}
