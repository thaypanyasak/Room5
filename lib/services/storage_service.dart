import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/member.dart';
import '../models/expense.dart';
import '../models/pre_stock_item.dart';
import '../models/period.dart';

class StorageService {
  static const String _keyMembers = 'room5_members';
  static const String _keyExpenses = 'room5_expenses';
  static const String _keyPreStock = 'room5_prestock';

  Future<void> saveMembers(List<Member> members) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = members.map((m) => m.toJson()).toList();
    await prefs.setString(_keyMembers, jsonEncode(jsonList));
  }

  Future<List<Member>> loadMembers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyMembers);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => Member.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = expenses.map((e) => e.toJson()).toList();
    await prefs.setString(_keyExpenses, jsonEncode(jsonList));
  }

  Future<List<Expense>> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyExpenses);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => Expense.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePreStockItems(List<PreStockItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((i) => i.toJson()).toList();
    await prefs.setString(_keyPreStock, jsonEncode(jsonList));
  }

  Future<List<PreStockItem>> loadPreStockItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyPreStock);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => PreStockItem.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static const String _keyPeriods = 'room5_periods';

  Future<void> savePeriods(List<Period> periods) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = periods.map((p) => p.toJson()).toList();
    await prefs.setString(_keyPeriods, jsonEncode(jsonList));
  }

  Future<List<Period>> loadPeriods() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyPeriods);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((j) => Period.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
