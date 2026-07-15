// lib/domain/models/album_model.dart

class Album {
  final String id;
  final String name;
  final DateTime createdAt;

  const Album({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, Object> toMap() {
    return <String, Object>{
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Album.fromMap(Map<String, Object?> map) {
    return Album(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int,
      ),
    );
  }
}
