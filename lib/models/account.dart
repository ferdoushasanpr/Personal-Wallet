enum RecordType { income, expense, transfer }

class Account {
  final String id;
  final String name;
  final String type; // Cash, Bank, etc.
  final int colorValue;
  final double initialBalance;
  final double currentBalance;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.colorValue,
    required this.initialBalance,
    required this.currentBalance,
  });

  Account copyWith({
    String? id,
    String? name,
    String? type,
    int? colorValue,
    double? initialBalance,
    double? currentBalance,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'colorValue': colorValue,
      'initialBalance': initialBalance,
      'currentBalance': currentBalance,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      colorValue: map['colorValue'],
      initialBalance: map['initialBalance'],
      currentBalance: map['currentBalance'],
    );
  }
}

class TransactionRecord {
  final String id;
  final String accountId;
  final String? targetAccountId; // Nullable, only for transfers
  final double amount;
  final RecordType type;
  final String category;
  final DateTime date;

  TransactionRecord({
    required this.id,
    required this.accountId,
    this.targetAccountId,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'accountId': accountId,
      'targetAccountId': targetAccountId,
      'amount': amount,
      'type': type.index, // Store enum as int
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  factory TransactionRecord.fromMap(Map<String, dynamic> map) {
    return TransactionRecord(
      id: map['id'],
      accountId: map['accountId'],
      targetAccountId: map['targetAccountId'],
      amount: map['amount'],
      type: RecordType.values[map['type']],
      category: map['category'],
      date: DateTime.parse(map['date']),
    );
  }
}
