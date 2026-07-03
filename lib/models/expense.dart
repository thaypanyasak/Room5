enum ExpenseCategory { kratom, utilities, food, other }

class Expense {
  final String id;
  final String title;
  final ExpenseCategory category;
  final double totalAmount;
  final DateTime date;
  
  // Specific fields for Kratom category
  final double? kratomAmount;
  final double? iceAmount;
  final String? kratomStockId;
  final String? syrupStockId;
  final int? kratomPortions;
  final int? syrupPortions;

  // Who paid how much: {memberId: amountPaid}
  final Map<String, double> payers;

  // List of member IDs who participate in sharing the cost
  final List<String> participantIds;

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.totalAmount,
    required this.date,
    this.kratomAmount,
    this.iceAmount,
    this.kratomStockId,
    this.syrupStockId,
    this.kratomPortions,
    this.syrupPortions,
    required this.payers,
    required this.participantIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category.name,
        'totalAmount': totalAmount,
        'date': date.toIso8601String(),
        'kratomAmount': kratomAmount,
        'iceAmount': iceAmount,
        'kratomStockId': kratomStockId,
        'syrupStockId': syrupStockId,
        'kratomPortions': kratomPortions,
        'syrupPortions': syrupPortions,
        'payers': payers,
        'participantIds': participantIds,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        title: json['title'] as String,
        category: ExpenseCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => ExpenseCategory.other,
        ),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String),
        kratomAmount: json['kratomAmount'] != null ? (json['kratomAmount'] as num).toDouble() : null,
        iceAmount: json['iceAmount'] != null ? (json['iceAmount'] as num).toDouble() : null,
        kratomStockId: json['kratomStockId'] as String?,
        syrupStockId: json['syrupStockId'] as String?,
        kratomPortions: json['kratomPortions'] as int?,
        syrupPortions: json['syrupPortions'] as int?,
        payers: (json['payers'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        participantIds: List<String>.from(json['participantIds'] as List),
      );

  Expense copyWith({
    String? id,
    String? title,
    ExpenseCategory? category,
    double? totalAmount,
    DateTime? date,
    double? kratomAmount,
    double? iceAmount,
    String? kratomStockId,
    String? syrupStockId,
    int? kratomPortions,
    int? syrupPortions,
    Map<String, double>? payers,
    List<String>? participantIds,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      totalAmount: totalAmount ?? this.totalAmount,
      date: date ?? this.date,
      kratomAmount: kratomAmount ?? this.kratomAmount,
      iceAmount: iceAmount ?? this.iceAmount,
      kratomStockId: kratomStockId ?? this.kratomStockId,
      syrupStockId: syrupStockId ?? this.syrupStockId,
      kratomPortions: kratomPortions ?? this.kratomPortions,
      syrupPortions: syrupPortions ?? this.syrupPortions,
      payers: payers ?? this.payers,
      participantIds: participantIds ?? this.participantIds,
    );
  }
}
