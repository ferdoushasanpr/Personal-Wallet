import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personalwallet/models/account.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:personalwallet/providers/account_provider.dart';
import 'package:personalwallet/constant/colors.dart';
import 'package:personalwallet/screens/add_account_screen.dart';
import 'package:personalwallet/screens/add_transaction_screen.dart';
import 'package:personalwallet/utilities/today_date.dart';

class AccountDetailsScreen extends ConsumerWidget {
  final Account account;
  const AccountDetailsScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider(account.id));

    final latestAccount = ref
        .watch(walletProvider)
        .accounts
        .firstWhere((a) => a.id == account.id, orElse: () => account);

    Widget _buildExpenseStructure(List<TransactionRecord> records) {
      final expenses = records
          .where((r) => r.type == RecordType.expense)
          .toList();

      if (expenses.isEmpty) {
        return const SizedBox(
          height: 200,
          child: Center(child: Text("No expenses recorded")),
        );
      }

      final Map<String, double> dataMap = {};
      double totalExpense = 0;
      for (var r in expenses) {
        dataMap[r.category] = (dataMap[r.category] ?? 0) + r.amount;
        totalExpense += r.amount;
      }

      final List<Color> colorPalette = [
        Colors.greenAccent,
        Colors.deepOrange,
        Colors.lightBlueAccent,
        Colors.blueGrey,
        Colors.amber,
      ];

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Expenses structure",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "LAST 30 DAYS",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              "BDT ${NumberFormat("#,##0.00").format(totalExpense)}",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      startDegreeOffset: -90,
                      sections: dataMap.entries.map((e) {
                        final index = dataMap.keys.toList().indexOf(e.key);
                        return PieChartSectionData(
                          value: e.value,
                          title: "",
                          radius: 25,
                          color: colorPalette[index % colorPalette.length],
                        );
                      }).toList(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "All",
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        Text(
                          "BDT ${totalExpense.toInt()}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: dataMap.keys.map((cat) {
                final index = dataMap.keys.toList().indexOf(cat);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colorPalette[index % colorPalette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    void _showDeleteConfirmation(
      BuildContext context,
      WidgetRef ref,
      Account account,
    ) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Delete Account?"),
          content: Text(
            "This will permanently remove ${account.name} and all its transaction history. This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                ref.read(walletProvider.notifier).deleteAccount(account.id);
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }

    void _confirmRecordDeletion(
      BuildContext context,
      WidgetRef ref,
      TransactionRecord record,
    ) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Delete Record?"),
          content: const Text(
            "This will remove the transaction and revert the balance changes.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(walletProvider.notifier).removeTransaction(record);
                Navigator.pop(ctx);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: AppColors.surface),
              ),
            ),
          ],
        ),
      );
    }

    void _showRecordOptions(
      BuildContext context,
      WidgetRef ref,
      TransactionRecord record,
    ) {
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text("Edit Record"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddTransactionScreen(
                      sourceAccount: account,
                      record: record,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete Record"),
              onTap: () {
                Navigator.pop(context);
                _confirmRecordDeletion(context, ref, record);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(latestAccount.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditAccountScreen(account: latestAccount),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(context, ref, latestAccount);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(sourceAccount: latestAccount),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Current Balance", style: TextStyle(color: Colors.grey[400])),
            Text(
              NumberFormat.currency(
                symbol: "BDT",
              ).format(latestAccount.currentBalance),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            transactionsAsync.when(
              data: (records) {
                return Column(
                  children: [
                    _buildExpenseStructure(records),
                    const SizedBox(height: 24),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text("Error: $err"),
            ),
            const SizedBox(height: 24),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            transactionsAsync.when(
              data: (records) {
                if (records.isEmpty)
                  return const Text("No transactions recorded.");
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) {
                    final r = records[i];
                    Color amountColor;
                    String prefix;

                    if (r.type == RecordType.income) {
                      amountColor = AppColors.accent;
                      prefix = "+";
                    } else if (r.type == RecordType.expense) {
                      amountColor = AppColors.error;
                      prefix = "-";
                    } else {
                      if (r.accountId == account.id) {
                        amountColor = Colors.orange;
                        prefix = "-";
                      } else {
                        amountColor = AppColors.accent;
                        prefix = "+";
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onLongPress: () => _showRecordOptions(context, ref, r),
                        leading: CircleAvatar(
                          backgroundColor: amountColor.withValues(alpha: 0.2),
                          child: Icon(
                            r.type == RecordType.transfer
                                ? Icons.swap_horiz
                                : (r.type == RecordType.income
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward),
                            color: amountColor,
                          ),
                        ),
                        title: Text(
                          r.category.isNotEmpty
                              ? r.category
                              : r.type.name.toUpperCase(),
                        ),
                        subtitle: Text(
                          isToday(r.date)
                              ? 'Today'
                              : DateFormat('MMM dd, yyyy').format(r.date),
                        ),

                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$prefix BDT${r.amount.toStringAsFixed(2)}",
                              style: TextStyle(
                                color: amountColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white24,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
