import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_helper.dart';
import '../models/weekly.dart';

final weeklyCalcProvider =
    StateNotifierProvider<WeeklyCalcNotifier, WeeklyCalcState>((ref) {
      return WeeklyCalcNotifier();
    });

class WeeklyCalcNotifier extends StateNotifier<WeeklyCalcState> {
  WeeklyCalcNotifier()
    : super(
        WeeklyCalcState(
          earns: List.filled(7, 0.0),
          spends: List.filled(7, 0.0),
          isLoading: true,
        ),
      ) {
    loadWeeklyData();
  }

  final List<String> _days = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];

  // Matches your loadAccounts() pattern
  Future<void> loadWeeklyData() async {
    final data = await DatabaseHelper.instance.getWeeklyStats();

    if (data != null) {
      List<double> loadedEarns = [];
      List<double> loadedSpends = [];

      for (var day in _days) {
        loadedEarns.add((data['${day}_earn'] as num?)?.toDouble() ?? 0.0);
        loadedSpends.add((data['${day}_spend'] as num?)?.toDouble() ?? 0.0);
      }

      state = state.copyWith(
        earns: loadedEarns,
        spends: loadedSpends,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
  }
}
