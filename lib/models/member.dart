class Member {
  final String id;
  final String name;
  final String avatarUrl;

  Member({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String,
      );

  Member copyWith({
    String? id,
    String? name,
    String? avatarUrl,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
