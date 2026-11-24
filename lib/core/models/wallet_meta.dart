class WalletMeta {
  final String id;
  final String name;
  final String address;

  const WalletMeta({
    required this.id,
    required this.name,
    required this.address,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
  };

  factory WalletMeta.fromJson(Map<String, dynamic> json) => WalletMeta(
    id: json['id'] as String,
    name: json['name'] as String,
    address: json['address'] as String,
  );
}
