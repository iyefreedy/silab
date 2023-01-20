class Room {
  final String name;
  final String description;
  final String image;

  Room({
    required this.name,
    required this.description,
    required this.image,
  });

  Room.fromJson(Map<String, Object?> json)
      : this(
          name: json['nama'] as String,
          description: json['keterangan'] as String,
          image: json['foto'] as String,
        );

  Map<String, dynamic> toJson() {
    return {
      'nama': name,
      'keterangan': description,
      'foto': image,
    };
  }
}
