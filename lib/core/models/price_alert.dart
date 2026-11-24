class PriceAlert {
  final String tokenId;
  final String symbol;
  final double targetPrice;
  final bool isAbove;
  final bool isActive;

  const PriceAlert({
    required this.tokenId,
    required this.symbol,
    required this.targetPrice,
    required this.isAbove,
    this.isActive = true,
  });

  PriceAlert copyWith({bool? isActive}) => PriceAlert(
        tokenId: tokenId,
        symbol: symbol,
        targetPrice: targetPrice,
        isAbove: isAbove,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        'symbol': symbol,
        'targetPrice': targetPrice,
        'isAbove': isAbove,
        'isActive': isActive,
      };

  factory PriceAlert.fromJson(Map<String, dynamic> json) => PriceAlert(
        tokenId: json['tokenId'] as String,
        symbol: json['symbol'] as String,
        targetPrice: (json['targetPrice'] as num).toDouble(),
        isAbove: json['isAbove'] as bool,
        isActive: json['isActive'] as bool? ?? true,
      );
}
