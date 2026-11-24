class AssetModel {
  final String id;
  final String symbol;
  final String name;
  final double balance;
  final double price;
  final double changePercentage24h;
  final String? iconPath; // Local asset or null for network image
  final int decimals;

  const AssetModel({
    required this.id,
    required this.symbol,
    required this.name,
    required this.balance,
    required this.price,
    required this.changePercentage24h,
    this.iconPath,
    this.decimals = 9,
  });

  double get valueUsd => balance * price;
  
  static String formatValue(double value) {
    if (value == 0) return '0';
    // If value is very small, show more decimals. Otherwise, show 4 max for clean list view.
    if (value < 0.0001) {
      return value.toStringAsFixed(8).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    // Standard formatting: max 4 decimals, trim trailing zeros
    String fixed = value.toStringAsFixed(4);
    if (fixed.contains('.')) {
      fixed = fixed.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return fixed;
  }

  String get formattedBalance => formatValue(balance);

  factory AssetModel.empty() {
    return const AssetModel(
      id: '',
      symbol: '',
      name: '',
      balance: 0.0,
      price: 0.0,
      changePercentage24h: 0.0,
      decimals: 9,
    );
  }
}
