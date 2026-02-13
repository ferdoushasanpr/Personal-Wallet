import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:personalwallet/models/account.dart';
import 'package:personalwallet/providers/account_provider.dart';

class AddEditAccountScreen extends ConsumerStatefulWidget {
  final Account? account;
  const AddEditAccountScreen({super.key, this.account});

  @override
  ConsumerState<AddEditAccountScreen> createState() =>
      _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends ConsumerState<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _balanceCtrl;
  String _type = "Cash";
  Color _color = Colors.blue;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account?.name ?? "");
    _balanceCtrl = TextEditingController(
      text: widget.account?.currentBalance.toString() ?? "",
    );
    _type = widget.account?.type ?? "Cash";
    _color = widget.account != null
        ? Color(widget.account!.colorValue)
        : Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.account == null ? "New Account" : "Edit Account"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Account Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: "Type",
                  border: OutlineInputBorder(),
                ),
                items: ["Cash", "Bank", "Mobile Wallet", "Savings"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Initial Balance",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Required" : null,
                enabled:
                    widget.account ==
                    null, // Lock balance on edit to prevent manual override without transaction
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text("Account Color"),
                trailing: CircleAvatar(backgroundColor: _color),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Pick a color"),
                      content: BlockPicker(
                        pickerColor: _color,
                        onColorChanged: (c) => setState(() => _color = c),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text("Select"),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (widget.account == null) {
                      ref
                          .read(walletProvider.notifier)
                          .addAccount(
                            _nameCtrl.text,
                            _type,
                            _color.value,
                            double.parse(_balanceCtrl.text),
                          );
                    } else {
                      final updated = Account(
                        id: widget.account!.id,
                        name: _nameCtrl.text,
                        type: _type,
                        colorValue: _color.value,
                        initialBalance: widget.account!.initialBalance,
                        currentBalance: widget
                            .account!
                            .currentBalance, // Keep current balance
                      );
                      ref.read(walletProvider.notifier).editAccount(updated);
                    }
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save Account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
