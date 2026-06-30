import 'expense.dart';
import 'pre_stock_item.dart';

class ArchivedTransfer {
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;

  ArchivedTransfer({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'fromId': fromId,
        'fromName': fromName,
        'toId': toId,
        'toName': toName,
        'amount': amount,
      };

  factory ArchivedTransfer.fromJson(Map<String, dynamic> json) => ArchivedTransfer(
        fromId: json['fromId'] ?? '',
        fromName: json['fromName'] ?? '',
        toId: json['toId'] ?? '',
        toName: json['toName'] ?? '',
        amount: (json['amount'] as num).toDouble(),
      );
}

class Period {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<Expense> expenses;
  final List<PreStockItem> preStockItems;
  final List<ArchivedTransfer> transfers;

  Period({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.expenses,
    required this.preStockItems,
    required this.transfers,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'preStockItems': preStockItems.map((i) => i.toJson()).toList(),
        'transfers': transfers.map((t) => t.toJson()).toList(),
      };

  factory Period.fromJson(Map<String, dynamic> json) => Period(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        expenses: (json['expenses'] as List? ?? [])
            .map((e) => Expense.fromJson(e as Map<String, dynamic>))
            .toList(),
        preStockItems: (json['preStockItems'] as List? ?? [])
            .map((i) => PreStockItem.fromJson(i as Map<String, dynamic>))
            .toList(),
        transfers: (json['transfers'] as List? ?? [])
            .map((t) => ArchivedTransfer.fromJson(t as Map<String, dynamic>))
            .toList(),
      );
}
