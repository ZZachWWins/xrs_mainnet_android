enum TransactionType {
  send,
  receive,
  swap,
}

enum TransactionStatus {
  confirmed,
  pending,
  failed,
}

class TransactionModel {
  final String id;
  final String date;
  final double amount;
  final String symbol;
  final TransactionType type;
  final TransactionStatus status;
  final String otherPartyAddress; // Sender if received, Recipient if sent

  const TransactionModel({
    required this.id,
    required this.date,
    required this.amount,
    required this.symbol,
    required this.type,
    required this.status,
    required this.otherPartyAddress,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      date: json['date'],
      amount: json['amount'],
      symbol: json['symbol'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.swap, // default fallback
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${json['status']}',
        orElse: () => TransactionStatus.failed, // default fallback
      ),
      otherPartyAddress: json['other_party_address'],
    );
  }
}
