import 'package:flutter/material.dart';
import 'package:personalwallet/constant/colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personalwallet/providers/weekly_provider.dart';

class WeeklyCalculationScreen extends ConsumerStatefulWidget {
  const WeeklyCalculationScreen({super.key});

  @override
  ConsumerState<WeeklyCalculationScreen> createState() =>
      _WeeklyCalculationScreenState();
}

class _WeeklyCalculationScreenState
    extends ConsumerState<WeeklyCalculationScreen> {
  late List<TextEditingController> _earnCtrls;
  late List<TextEditingController> _spendCtrls;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(weeklyCalcProvider);
    _earnCtrls = List.generate(
      7,
      (i) => TextEditingController(
        text: initialState.earns[i] == 0
            ? ""
            : initialState.earns[i].toString(),
      ),
    );
    _spendCtrls = List.generate(
      7,
      (i) => TextEditingController(
        text: initialState.spends[i] == 0
            ? ""
            : initialState.spends[i].toString(),
      ),
    );

    Future.delayed(Duration.zero, () {
      ref.listenManual(weeklyCalcProvider, (previous, next) {
        if (previous?.isLoading == true && next.isLoading == false) {
          setState(() {
            for (int i = 0; i < 7; i++) {
              _earnCtrls[i].text = next.earns[i] == 0
                  ? ""
                  : next.earns[i].toString();
              _spendCtrls[i].text = next.spends[i] == 0
                  ? ""
                  : next.spends[i].toString();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    for (var c in _earnCtrls) {
      c.dispose();
    }
    for (var c in _spendCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleUpdate(int index, String value, bool isEarn) {
    final doubleVal = double.tryParse(value) ?? 0.0;
    ref
        .read(weeklyCalcProvider.notifier)
        .updateDayValue(index, doubleVal, isEarn);
  }

  void _resetData() {
    ref.read(weeklyCalcProvider.notifier).resetCalculator();
    for (var c in _earnCtrls) {
      c.clear();
    }
    for (var c in _spendCtrls) {
      c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to update the Summary Header automatically
    final calcState = ref.watch(weeklyCalcProvider);
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

    // Calculate totals from the global state
    double totalEarn = calcState.earns.fold(0, (a, b) => a + b);
    double totalSpend = calcState.spends.fold(0, (a, b) => a + b);
    double totalSave = totalEarn - totalSpend;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Weekly Calculator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.orangeAccent),
            onPressed: () {
              // Confirmation Dialog
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Reset Week?"),
                  content: const Text("This will clear all daily entries."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        _resetData();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        "Reset",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Header
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surface,
            child: Column(
              children: [
                const Text(
                  "Weekly Summary",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem("Earnings", totalEarn, Colors.green),
                    _summaryItem("Spending", totalSpend, Colors.red),
                    _summaryItem("Savings", totalSave, Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Daily Status",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 7,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (ctx, i) {
                // Get live saving calculation for each row
                final dailySave = calcState.earns[i] - calcState.spends[i];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          days[i],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _earnCtrls[i],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "Earn",
                            isDense: true,
                          ),
                          onChanged: (v) => _handleUpdate(i, v, true),
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _spendCtrls[i],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: "Spend",
                            isDense: true,
                          ),
                          onChanged: (v) => _handleUpdate(i, v, false),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 60,
                        child: Text(
                          dailySave.toStringAsFixed(0),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: dailySave >= 0 ? Colors.blue : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          val.toStringAsFixed(0),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
