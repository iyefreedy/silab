import 'package:cloud_firestore/cloud_firestore.dart';

class Tool {
  final String roomId;
  final String name;
  final int quantity;
  final String description;
  final String? image;
  final String status;
  final DateTime purchasedDate;
  // final bool? selected;

  Tool({
    required this.roomId,
    required this.name,
    required this.quantity,
    required this.description,
    required this.image,
    required this.status,
    required this.purchasedDate,
    // this.selected,
  });

  Tool copyWith({
    String? roomId,
    String? name,
    int? quantity,
    String? description,
    String? image,
    String? status,
    DateTime? purchasedDate,
  }) =>
      Tool(
        roomId: roomId ?? this.roomId,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        description: description ?? this.description,
        image: image ?? this.image,
        status: status ?? this.status,
        purchasedDate: purchasedDate ?? this.purchasedDate,
      );

  Tool.fromJson(Map<String, Object?> json)
      : this(
          roomId: json['roomId'] as String,
          name: json['nama'] as String,
          quantity: json['kuantitas'] as int,
          description: json['keterangan'] as String,
          image: json['foto'] as String?,
          status: json['status'] as String,
          purchasedDate: (json['tanggalBeli'] as Timestamp).toDate(),
          // selected: json['selected'] as bool?,
        );

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'nama': name,
      'kuantitas': quantity,
      'keterangan': description,
      'foto': image,
      'status': status,
      'tanggalBeli': purchasedDate,
      // 'selected': selected,
    };
  }
}
