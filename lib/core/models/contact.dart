import 'package:uuid/uuid.dart';

class Contact {
  final String id;
  final String name;
  final String address;
  final String? note;
  final DateTime createdAt;

  const Contact({
    required this.id,
    required this.name,
    required this.address,
    this.note,
    required this.createdAt,
  });

  factory Contact.create({
    required String name,
    required String address,
    String? note,
  }) {
    return Contact(
      id: const Uuid().v4(),
      name: name,
      address: address,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  Contact copyWith({
    String? name,
    String? address,
    String? note,
  }) {
    return Contact(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'],
    name: json['name'],
    address: json['address'],
    note: json['note'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
