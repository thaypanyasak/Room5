class PreStockItem {
  final String id;
  final String itemName;
  final double totalCost;
  final String buyerId;
  final DateTime date;
  final String notes;
  final String type; // 'kratom' or 'syrup'
  final bool isOutOfStock;
  final int portions; // Number of estimated portions/uses
  final int? initialRemainingPortions; // Remaining portions when recorded

  PreStockItem({
    required this.id,
    required this.itemName,
    required this.totalCost,
    required this.buyerId,
    required this.date,
    required this.notes,
    this.type = 'kratom',
    this.isOutOfStock = false,
    this.portions = 10,
    this.initialRemainingPortions,
  });

  int get startingPortions => initialRemainingPortions ?? portions;

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemName': itemName,
        'totalCost': totalCost,
        'buyerId': buyerId,
        'date': date.toIso8601String(),
        'notes': notes,
        'type': type,
        'isOutOfStock': isOutOfStock,
        'portions': portions,
        'initialRemainingPortions': initialRemainingPortions,
      };

  factory PreStockItem.fromJson(Map<String, dynamic> json) => PreStockItem(
        id: json['id'] as String,
        itemName: json['itemName'] as String,
        totalCost: (json['totalCost'] as num).toDouble(),
        buyerId: json['buyerId'] as String,
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String,
        type: json['type'] as String? ?? 'kratom',
        isOutOfStock: json['isOutOfStock'] as bool? ?? false,
        portions: json['portions'] as int? ?? (json['type'] == 'syrup' ? 50 : 10),
        initialRemainingPortions: json['initialRemainingPortions'] as int?,
      );

  PreStockItem copyWith({
    String? id,
    String? itemName,
    double? totalCost,
    String? buyerId,
    DateTime? date,
    String? notes,
    String? type,
    bool? isOutOfStock,
    int? portions,
    int? initialRemainingPortions,
  }) {
    return PreStockItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      totalCost: totalCost ?? this.totalCost,
      buyerId: buyerId ?? this.buyerId,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      type: type ?? this.type,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      portions: portions ?? this.portions,
      initialRemainingPortions: initialRemainingPortions ?? this.initialRemainingPortions,
    );
  }
}
