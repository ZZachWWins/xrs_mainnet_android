// ignore_for_file: avoid_print
import 'package:xeris_wallet/core/services/xeris_api_service.dart';

void main() async {
  try {
    final txs = await XerisApiService.getTransactions(address: "8evPjjozSHNcoGRcv7zzxwan9sf3ubJ8q9CFzms6AK97");
    print("Count: ${txs?.data.length}");
    if (txs != null && txs.data.isNotEmpty) {
      print("First TX amt XRS: ${txs.data.first.amountXrs}");
    } else {
      print("No data or null");
    }
  } catch(e) {
    print("Error in script: $e");
  }
}
