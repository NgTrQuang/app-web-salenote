class Interaction {
  final int? id;
  final int customerId;
  final String content;
  final int createdAt;

  Interaction({
    this.id,
    required this.customerId,
    required this.content,
    required this.createdAt,
  });

  factory Interaction.fromMap(Map<String, dynamic> map) {
    return Interaction(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      content: map['content'] as String,
      createdAt: map['created_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'content': content,
      'created_at': createdAt,
    };
  }
}
