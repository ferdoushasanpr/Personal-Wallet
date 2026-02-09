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
