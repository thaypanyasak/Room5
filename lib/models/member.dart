class Member {
  final String id;
  final String name;
  final String avatarUrl;
  final String? qrPath;

  Member({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.qrPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'qrPath': qrPath,
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatarUrl'] as String,
        qrPath: json['qrPath'] as String?,
      );

  Member copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? qrPath,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      qrPath: qrPath ?? this.qrPath,
    );
  }
}
