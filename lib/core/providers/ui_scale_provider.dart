import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xeris_wallet/core/services/storage_service.dart';

const uiScaleSteps = [0.85, 0.95, 1.0, 1.1, 1.2];
const uiScaleLabels = ['XS', 'S', 'M', 'L', 'XL'];

final uiScaleProvider = NotifierProvider<UiScaleNotifier, double>(() {
  return UiScaleNotifier();
});

class UiScaleNotifier extends Notifier<double> {
  @override
  double build() {
    StorageService.getUiScale().then((v) => state = v);
    return 0.85;
  }

  Future<void> setScale(double scale) async {
    state = scale;
    await StorageService.setUiScale(scale);
  }
}
