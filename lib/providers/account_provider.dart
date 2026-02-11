import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/database_helper.dart';
import '../models/account.dart';

// --- State Classes ---
class WalletState {
  final List<Account> accounts;
  final bool isLoading;

  WalletState({this.accounts = const [], this.isLoading = true});
}

// --- Notifier ---
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

    // Update Logic based on Clean Architecture (Use Cases)
    // 1. Update Source Account
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

    // 2. If Transfer, Update Target Account
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

    await loadAccounts(); // Refresh UI
  }

  Future<void> updateTransaction(
    TransactionRecord oldRecord,
    TransactionRecord newRecord,
  ) async {
    // 1. Revert the balance impact of the OLD record
    final account = state.accounts.firstWhere(
      (a) => a.id == oldRecord.accountId,
    );
    double balanceAfterRevert = account.currentBalance;

    if (oldRecord.type == RecordType.income)
      balanceAfterRevert -= oldRecord.amount;
    else
      balanceAfterRevert += oldRecord.amount;

    // 2. Apply the balance impact of the NEW record
    double finalBalance = balanceAfterRevert;
    if (newRecord.type == RecordType.income)
      finalBalance += newRecord.amount;
    else
      finalBalance -= newRecord.amount;

    // 3. Update Database
    await DatabaseHelper.instance.updateRecord(newRecord);
    await DatabaseHelper.instance.updateAccount(
      account.copyWith(currentBalance: finalBalance),
    );

    // 4. Refresh State
    await loadAccounts();
  }

  // Inside WalletNotifier class
  Future<void> removeTransaction(TransactionRecord record) async {
    final db = DatabaseHelper.instance;

    // 1. Delete the record from SQLite
    await db.deleteRecord(record.id);

    // 2. Revert the balance change on the account
    final account = state.accounts.firstWhere((a) => a.id == record.accountId);
    double revertedBalance = account.currentBalance;

    if (record.type == RecordType.income) {
      revertedBalance -= record.amount; // Remove income
    } else if (record.type == RecordType.expense) {
      revertedBalance += record.amount; // Add back expense
    } else if (record.type == RecordType.transfer) {
      revertedBalance += record.amount; // Add back transferred out money

      // Also revert target account if it's a transfer
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

    // 3. Refresh state
    await loadAccounts();
  }
}

// --- Providers ---
final walletProvider = StateNotifierProvider<WalletNotifier, WalletState>((
  ref,
) {
  return WalletNotifier();
});

// A provider to fetch transactions for a specific account dynamically
final transactionsProvider =
    FutureProvider.family<List<TransactionRecord>, String>((
      ref,
      accountId,
    ) async {
      // Watch wallet provider to re-fetch when accounts change (implies transactions might have changed)
      ref.watch(walletProvider);
      return await DatabaseHelper.instance.getRecordsByAccount(accountId);
    });
