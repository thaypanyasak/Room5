import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/member.dart';
import '../models/expense.dart';
import '../models/pre_stock_item.dart';
import '../models/period.dart';
import '../services/storage_service.dart';

export '../models/member.dart';
export '../models/expense.dart';
export '../models/pre_stock_item.dart';
export '../models/period.dart';

class Transfer {
  final Member from;
  final Member to;
  final double amount;

  Transfer({
    required this.from,
    required this.to,
    required this.amount,
  });
}

class FinanceState {
  final List<Member> members;
  final List<Expense> expenses;
  final List<PreStockItem> preStockItems;
  final List<Period> periods;
  final bool isLoading;

  FinanceState({
    this.members = const [],
    this.expenses = const [],
    this.preStockItems = const [],
    this.periods = const [],
    this.isLoading = false,
  });

  FinanceState copyWith({
    List<Member>? members,
    List<Expense>? expenses,
    List<PreStockItem>? preStockItems,
    List<Period>? periods,
    bool? isLoading,
  }) {
    return FinanceState(
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
      preStockItems: preStockItems ?? this.preStockItems,
      periods: periods ?? this.periods,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FinanceNotifier extends Notifier<FinanceState> {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  @override
  FinanceState build() {
    // Trigger async load
    _initializeData();
    return FinanceState(isLoading: true);
  }

  Future<void> _initializeData() async {
    var members = await _storage.loadMembers();
    final expenses = await _storage.loadExpenses();
    final preStock = await _storage.loadPreStockItems();
    final periods = await _storage.loadPeriods();

    // Default members if empty
    if (members.isEmpty) {
      members = [
        Member(id: 'Thay', name: 'Thay', avatarUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Thay'),
        Member(id: 'Ley', name: 'Ley', avatarUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=Ley'),
        Member(id: 'Bualy', name: 'Bualy', avatarUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Bualy'),
        Member(id: 'Thui', name: 'Thui', avatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Thui'),
        Member(id: 'Mei', name: 'Mei', avatarUrl: 'https://api.dicebear.com/7.x/avataaars/png?seed=Mei'),
      ];
      await _storage.saveMembers(members);
    } else {
      bool updated = false;
      members = members.map((m) {
        if (m.id == 'Thay' && m.avatarUrl.contains('avataaars')) {
          updated = true;
          return m.copyWith(avatarUrl: 'https://api.dicebear.com/7.x/adventurer/png?seed=Thay');
        }
        if (m.id == 'Ley' && m.avatarUrl.contains('avataaars')) {
          updated = true;
          return m.copyWith(avatarUrl: 'https://api.dicebear.com/7.x/lorelei/png?seed=Ley');
        }
        if (m.id == 'Bualy' && m.avatarUrl.contains('avataaars')) {
          updated = true;
          return m.copyWith(avatarUrl: 'https://api.dicebear.com/7.x/fun-emoji/png?seed=Bualy');
        }
        if (m.id == 'Thui' && m.avatarUrl.contains('avataaars')) {
          updated = true;
          return m.copyWith(avatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=Thui');
        }
        return m;
      }).toList();
      if (updated) {
        await _storage.saveMembers(members);
      }
    }

    state = FinanceState(
      members: members,
      expenses: expenses,
      preStockItems: preStock,
      periods: periods,
      isLoading: false,
    );
  }

  // Member management
  Future<void> addMember(String name) async {
    final styles = ['adventurer', 'lorelei', 'fun-emoji', 'bottts', 'avataaars', 'pixel-art', 'croodles'];
    final style = styles[name.hashCode % styles.length];
    
    final newMember = Member(
      id: _uuid.v4(),
      name: name,
      avatarUrl: 'https://api.dicebear.com/7.x/$style/png?seed=$name',
    );
    final updatedList = [...state.members, newMember];
    state = state.copyWith(members: updatedList);
    await _storage.saveMembers(updatedList);
  }

  Future<void> deleteMember(String id) async {
    final updatedList = state.members.where((m) => m.id != id).toList();
    state = state.copyWith(members: updatedList);
    await _storage.saveMembers(updatedList);
  }

  Future<void> updateMemberAvatar(String memberId, String avatarUrl) async {
    final updatedList = state.members.map((m) {
      if (m.id == memberId) {
        return m.copyWith(avatarUrl: avatarUrl);
      }
      return m;
    }).toList();
    state = state.copyWith(members: updatedList);
    await _storage.saveMembers(updatedList);
  }

  Future<void> updateMemberQR(String memberId, String? qrPath) async {
    final updatedList = state.members.map((m) {
      if (m.id == memberId) {
        return m.copyWith(qrPath: qrPath);
      }
      return m;
    }).toList();
    state = state.copyWith(members: updatedList);
    await _storage.saveMembers(updatedList);
  }

  // Expense management
  Future<void> addExpense(Expense expense) async {
    final updatedList = [expense, ...state.expenses];
    state = state.copyWith(expenses: updatedList);
    await _storage.saveExpenses(updatedList);
  }

  Future<void> deleteExpense(String id) async {
    final updatedList = state.expenses.where((e) => e.id != id).toList();
    state = state.copyWith(expenses: updatedList);
    await _storage.saveExpenses(updatedList);
  }

  Future<void> updateExpense(Expense updatedExpense) async {
    final updatedList = state.expenses.map((e) {
      if (e.id == updatedExpense.id) {
        return updatedExpense;
      }
      return e;
    }).toList();
    state = state.copyWith(expenses: updatedList);
    await _storage.saveExpenses(updatedList);
  }

  // Pre-stocked items management
  Future<void> addPreStockItem(PreStockItem item) async {
    final updatedList = [item, ...state.preStockItems];
    state = state.copyWith(preStockItems: updatedList);
    await _storage.savePreStockItems(updatedList);
  }

  Future<void> deletePreStockItem(String id) async {
    final updatedList = state.preStockItems.where((i) => i.id != id).toList();
    state = state.copyWith(preStockItems: updatedList);
    await _storage.savePreStockItems(updatedList);
  }

  Future<void> togglePreStockItemStatus(String id) async {
    final updatedList = state.preStockItems.map((item) {
      if (item.id == id) {
        return item.copyWith(isOutOfStock: !item.isOutOfStock);
      }
      return item;
    }).toList();
    state = state.copyWith(preStockItems: updatedList);
    await _storage.savePreStockItems(updatedList);
  }

  Future<void> updatePreStockItem(PreStockItem updatedItem) async {
    final updatedList = state.preStockItems.map((item) {
      if (item.id == updatedItem.id) {
        return updatedItem;
      }
      return item;
    }).toList();
    state = state.copyWith(preStockItems: updatedList);
    await _storage.savePreStockItems(updatedList);
  }

  // Balance calculations: Returns {MemberId: NetBalance}
  Map<String, double> calculateBalances() {
    final balances = <String, double>{};
    
    // Initialize
    for (var m in state.members) {
      balances[m.id] = 0.0;
    }

    // Process expenses
    for (var expense in state.expenses) {
      // Add credits (amounts paid)
      expense.payers.forEach((payerId, paidAmount) {
        if (balances.containsKey(payerId)) {
          balances[payerId] = balances[payerId]! + paidAmount;
        }
      });

      // Deduct debits (split shares)
      if (expense.participantIds.isNotEmpty) {
        final share = expense.totalAmount / expense.participantIds.length;
        for (var partId in expense.participantIds) {
          if (balances.containsKey(partId)) {
            balances[partId] = balances[partId]! - share;
          }
        }
      }
    }

    // Process consumption of pre-stocked items from expenses (debit participants, credit buyer)
    for (var expense in state.expenses) {
      if (expense.category == ExpenseCategory.kratom && expense.participantIds.isNotEmpty) {
        // Kratom Leaf consumption portion
        if (expense.kratomStockId != null) {
          final preItem = state.preStockItems.firstWhere(
            (i) => i.id == expense.kratomStockId,
            orElse: () => PreStockItem(id: '', itemName: '', totalCost: 0.0, buyerId: '', date: DateTime.now(), notes: '', portions: 1),
          );
          if (preItem.id.isNotEmpty && preItem.totalCost > 0) {
            final portionCost = preItem.totalCost / (preItem.portions > 0 ? preItem.portions : 1);
            final consumedCost = portionCost * (expense.kratomPortions ?? 1);
            
            // Debit the session participants
            final participantShare = consumedCost / expense.participantIds.length;
            for (var partId in expense.participantIds) {
              if (balances.containsKey(partId)) {
                balances[partId] = balances[partId]! - participantShare;
              }
            }

            // Credit the buyer of this stock item for this consumed portion!
            final buyerId = preItem.buyerId;
            if (balances.containsKey(buyerId)) {
              balances[buyerId] = balances[buyerId]! + consumedCost;
            }
          }
        }

        // Syrup/Syrup portion
        if (expense.syrupStockId != null) {
          final preItem = state.preStockItems.firstWhere(
            (i) => i.id == expense.syrupStockId,
            orElse: () => PreStockItem(id: '', itemName: '', totalCost: 0.0, buyerId: '', date: DateTime.now(), notes: '', portions: 1),
          );
          if (preItem.id.isNotEmpty && preItem.totalCost > 0) {
            final portionCost = preItem.totalCost / (preItem.portions > 0 ? preItem.portions : 1);
            final consumedCost = portionCost * (expense.syrupPortions ?? 1);
            
            // Debit the session participants
            final participantShare = consumedCost / expense.participantIds.length;
            for (var partId in expense.participantIds) {
              if (balances.containsKey(partId)) {
                balances[partId] = balances[partId]! - participantShare;
              }
            }

            // Credit the buyer of this stock item for this consumed portion!
            final buyerId = preItem.buyerId;
            if (balances.containsKey(buyerId)) {
              balances[buyerId] = balances[buyerId]! + consumedCost;
            }
          }
        }
      }
    }

    return balances;
  }

  // Debt minimization algorithm (Who should pay whom, how much)
  List<Transfer> calculateOptimizedTransfers() {
    final balances = calculateBalances();
    
    // Group into Debtors (Net < 0) and Creditors (Net > 0)
    final debtors = <_MemberBalance>[];
    final creditors = <_MemberBalance>[];

    balances.forEach((memberId, balance) {
      final member = state.members.firstWhere((m) => m.id == memberId, orElse: () => Member(id: memberId, name: memberId, avatarUrl: ''));
      if (balance < -0.01) {
        debtors.add(_MemberBalance(member, balance));
      } else if (balance > 0.01) {
        creditors.add(_MemberBalance(member, balance));
      }
    });

    // Sort: Debtors ascending (most negative first), Creditors descending (most positive first)
    debtors.sort((a, b) => a.balance.compareTo(b.balance));
    creditors.sort((a, b) => b.balance.compareTo(a.balance));

    final transfers = <Transfer>[];
    int dIdx = 0;
    int cIdx = 0;

    while (dIdx < debtors.length && cIdx < creditors.length) {
      final debtor = debtors[dIdx];
      final creditor = creditors[cIdx];

      final debtorOwes = debtor.balance.abs();
      final creditorReceives = creditor.balance;

      final transferAmount = debtorOwes < creditorReceives ? debtorOwes : creditorReceives;

      transfers.add(Transfer(
        from: debtor.member,
        to: creditor.member,
        amount: transferAmount,
      ));

      // Update balances
      debtor.balance += transferAmount;
      creditor.balance -= transferAmount;

      if (debtor.balance.abs() < 0.01) {
        dIdx++;
      }
      if (creditor.balance < 0.01) {
        cIdx++;
      }
    }

    return transfers;
  }

  Future<void> settleAndStartNewPeriod({
    required String periodName,
    required bool keepRemainingStock,
  }) async {
    final transfers = calculateOptimizedTransfers();
    final archivedTransfers = transfers.map((t) => ArchivedTransfer(
      fromId: t.from.id,
      fromName: t.from.name,
      toId: t.to.id,
      toName: t.to.name,
      amount: t.amount,
    )).toList();

    DateTime startDate = DateTime.now();
    if (state.expenses.isNotEmpty) {
      startDate = state.expenses.map((e) => e.date).reduce((a, b) => a.isBefore(b) ? a : b);
    } else if (state.preStockItems.isNotEmpty) {
      startDate = state.preStockItems.map((i) => i.date).reduce((a, b) => a.isBefore(b) ? a : b);
    }

    final newPeriod = Period(
      id: _uuid.v4(),
      name: periodName,
      startDate: startDate,
      endDate: DateTime.now(),
      expenses: state.expenses,
      preStockItems: state.preStockItems,
      transfers: archivedTransfers,
    );

    final updatedPeriods = [...state.periods, newPeriod];

    final List<PreStockItem> carriedOverStock = [];
    if (keepRemainingStock) {
      for (var item in state.preStockItems) {
        final usedCount = state.expenses.fold<int>(0, (sum, e) {
          if (item.type == 'kratom' && e.kratomStockId == item.id) {
            return sum + (e.kratomPortions ?? 1);
          }
          if (item.type == 'syrup' && e.syrupStockId == item.id) {
            return sum + (e.syrupPortions ?? 1);
          }
          return sum;
        });
        final remainingPortions = item.startingPortions - usedCount;
        if (remainingPortions > 0) {
          final portionCost = item.totalCost / (item.portions > 0 ? item.portions : 1);
          final remainingCost = remainingPortions * portionCost;
          
          carriedOverStock.add(PreStockItem(
            id: _uuid.v4(),
            itemName: item.itemName,
            type: item.type,
            totalCost: remainingCost,
            buyerId: item.buyerId,
            date: DateTime.now(),
            notes: '${item.notes.isNotEmpty ? "${item.notes} • " : ""}ຍົກມາຈາກ ${periodName}',
            portions: remainingPortions,
            isOutOfStock: false,
          ));
        }
      }
    }

    state = state.copyWith(
      expenses: [],
      preStockItems: carriedOverStock,
      periods: updatedPeriods,
    );

    await _storage.saveExpenses([]);
    await _storage.savePreStockItems(carriedOverStock);
    await _storage.savePeriods(updatedPeriods);
  }

  Future<void> deletePeriod(String id) async {
    final updatedPeriods = state.periods.where((p) => p.id != id).toList();
    state = state.copyWith(periods: updatedPeriods);
    await _storage.savePeriods(updatedPeriods);
  }
}

class _MemberBalance {
  final Member member;
  double balance;

  _MemberBalance(this.member, this.balance);
}

final financeProvider = NotifierProvider<FinanceNotifier, FinanceState>(FinanceNotifier.new);
