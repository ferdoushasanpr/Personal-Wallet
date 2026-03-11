import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/database_helper.dart';
import '../models/account.dart';

class WalletState {
  final List<Account> accounts;
  final bool isLoading;

  WalletState({this.accounts = const [], this.isLoading = true});
}

class WalletNotifier extends StateNotifier<WalletState> {
  WalletNotifier() : super(WalletState()) {
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final accounts = await DatabaseHelper.instance.getAllAccounts();
    state = WalletState(accounts: accounts, isLoading: false);
  }

  Future<void> addAccount(
    String name,
    String type,
    int colorValue,
    double initialBalance,
  ) async {
    final newAccount = Account(
      id: const Uuid().v4(),
      name: name,
      type: type,
      colorValue: colorValue,
      initialBalance: initialBalance,
      currentBalance: initialBalance,
    );
    await DatabaseHelper.instance.insertAccount(newAccount);
    await loadAccounts();
  }

  Future<void> editAccount(Account updatedAccount) async {
    await DatabaseHelper.instance.updateAccount(updatedAccount);
    await loadAccounts();
  }

  Future<void> deleteAccount(String accountId) async {
    await DatabaseHelper.instance.deleteAccount(accountId);
    await loadAccounts();
  }

  Future<void> addTransaction(TransactionRecord record) async {
    final db = DatabaseHelper.instance;
    await db.insertRecord(record);

    final sourceAccount = state.accounts.firstWhere(
      (a) => a.id == record.accountId,
    );
    double newSourceBalance = sourceAccount.currentBalance;

    if (record.type == RecordType.expense ||
        record.type == RecordType.transfer) {
      newSourceBalance -= record.amount;
    } else if (record.type == RecordType.income) {
      newSourceBalance += record.amount;
    }

    final updatedSource = Account(
      id: sourceAccount.id,
      name: sourceAccount.name,
      type: sourceAccount.type,
      colorValue: sourceAccount.colorValue,
      initialBalance: sourceAccount.initialBalance,
      currentBalance: newSourceBalance,
    );
    await db.updateAccount(updatedSource);

    if (record.type == RecordType.transfer && record.targetAccountId != null) {
      final targetAccount = state.accounts.firstWhere(
        (a) => a.id == record.targetAccountId,
      );
      final updatedTarget = Account(
        id: targetAccount.id,
        name: targetAccount.name,
        type: targetAccount.type,
        colorValue: targetAccount.colorValue,
        initialBalance: targetAccount.initialBalance,
        currentBalance: targetAccount.currentBalance + record.amount,
      );
      await db.updateAccount(updatedTarget);
    }

    await loadAccounts();
  }

  Future<void> updateTransaction(
    TransactionRecord oldRecord,
    TransactionRecord newRecord,
  ) async {
    final account = state.accounts.firstWhere(
      (a) => a.id == oldRecord.accountId,
    );
    double balanceAfterRevert = account.currentBalance;

    if (oldRecord.type == RecordType.income) {
      balanceAfterRevert -= oldRecord.amount;
    } else {
      balanceAfterRevert += oldRecord.amount;
    }

    double finalBalance = balanceAfterRevert;
    if (newRecord.type == RecordType.income) {
      finalBalance += newRecord.amount;
    } else {
      finalBalance -= newRecord.amount;
    }

    await DatabaseHelper.instance.updateRecord(newRecord);
    await DatabaseHelper.instance.updateAccount(
      account.copyWith(currentBalance: finalBalance),
    );

    await loadAccounts();
  }

  Future<void> removeTransaction(TransactionRecord record) async {
    final db = DatabaseHelper.instance;

    await db.deleteRecord(record.id);

    final account = state.accounts.firstWhere((a) => a.id == record.accountId);
    double revertedBalance = account.currentBalance;

    if (record.type == RecordType.income) {
      revertedBalance -= record.amount;
    } else if (record.type == RecordType.expense) {
      revertedBalance += record.amount;
    } else if (record.type == RecordType.transfer) {
      revertedBalance += record.amount;

      if (record.targetAccountId != null) {
        final targetAccount = state.accounts.firstWhere(
          (a) => a.id == record.targetAccountId,
        );
        final updatedTarget = targetAccount.copyWith(
          currentBalance: targetAccount.currentBalance - record.amount,
        );
        await db.updateAccount(updatedTarget);
      }
    }

    final updatedSource = account.copyWith(currentBalance: revertedBalance);
    await db.updateAccount(updatedSource);

    await loadAccounts();
  }
}

final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((
  ref,
) {
  return WalletNotifier();
});

final transactionsProvider =
    FutureProvider.family<List<TransactionRecord>, String>((
      ref,
      accountId,
    ) async {
      ref.watch(walletProvider);
      return await DatabaseHelper.instance.getRecordsByAccount(accountId);
    });
