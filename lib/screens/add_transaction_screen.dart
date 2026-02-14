import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:personalwallet/models/account.dart';
import 'package:personalwallet/providers/account_provider.dart';
import 'package:personalwallet/constant/colors.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Account sourceAccount;
  final TransactionRecord? record;

  const AddTransactionScreen({
    super.key,
    required this.sourceAccount,
    this.record,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  late TextEditingController _categoryCtrl;
  late RecordType _type;
  String? _targetAccountId;

  final List<String> _incomeCategories = [
    "Salary",
    "Business",
    "Investment",
    "Gift",
    "Transportation",
    "Other",
  ];
  final List<String> _expenseCategories = [
    "Food & Drinks",
    "Shopping",
    "Transportation",
    "Life & Entertainment",
    "Utilities",
    "Health",
    "Other",
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.record?.amount.toString() ?? "",
    );
    _categoryCtrl = TextEditingController(text: widget.record?.category ?? "");
    _type = widget.record?.type ?? RecordType.expense;
    _targetAccountId = widget.record?.targetAccountId;
  }

  @override
  Widget build(BuildContext context) {
    final allAccounts = ref.watch(walletProvider).accounts;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record != null ? "Edit Record" : "New Record"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Type Selector
              Row(
                children: [
                  Expanded(
                    child: _buildTypeBtn(
                      RecordType.income,
                      "Income",
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeBtn(
                      RecordType.expense,
                      "Expense",
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTypeBtn(
                      RecordType.transfer,
                      "Transfer",
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                  prefixText: "\$ ",
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              if (_type != RecordType.transfer)
                DropdownButtonFormField<String>(
                  value:
                      (_type == RecordType.income
                          ? _incomeCategories.contains(_categoryCtrl.text)
                          : _expenseCategories.contains(_categoryCtrl.text))
                      ? _categoryCtrl.text
                      : null,
                  decoration: const InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  // Switch the list based on whether it's Income or Expense
                  items:
                      (_type == RecordType.income
                              ? _incomeCategories
                              : _expenseCategories)
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoryCtrl.text = value!;
                    });
                  },
                  validator: (v) =>
                      v == null ? "Please select a category" : null,
                  dropdownColor: AppColors.surface, // Matches your dark theme
                ),
              if (_type == RecordType.transfer) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _targetAccountId,
                  decoration: const InputDecoration(
                    labelText: "To Account",
                    border: OutlineInputBorder(),
                  ),
                  items: allAccounts
                      .where((a) => a.id != widget.sourceAccount.id)
                      .map(
                        (e) =>
                            DropdownMenuItem(value: e.id, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _targetAccountId = v),
                  validator: (v) => v == null ? "Select destination" : null,
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Create the record object
                    final recordData = TransactionRecord(
                      id:
                          widget.record?.id ??
                          const Uuid().v4(), // CRITICAL: Use old ID if editing
                      accountId: widget.sourceAccount.id,
                      targetAccountId: _type == RecordType.transfer
                          ? _targetAccountId
                          : null,
                      amount: double.parse(_amountCtrl.text),
                      type: _type,
                      category: _type == RecordType.transfer
                          ? "Transfer"
                          : _categoryCtrl.text,
                      date: widget.record?.date ?? DateTime.now(),
                    );

                    if (widget.record != null) {
                      // USE UPDATE METHOD
                      await ref
                          .read(walletProvider.notifier)
                          .updateTransaction(widget.record!, recordData);
                    } else {
                      // USE ADD METHOD
                      await ref
                          .read(walletProvider.notifier)
                          .addTransaction(recordData);
                    }

                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text("Save Record"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBtn(RecordType type, String label, Color color) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
