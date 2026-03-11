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

  Future<void> updateDayValue(int index, double value, bool isEarn) async {
    final newEarns = [...state.earns];
    final newSpends = [...state.spends];

    if (isEarn) {
      newEarns[index] = value;
    } else {
      newSpends[index] = value;
    }

    state = state.copyWith(earns: newEarns, spends: newSpends);

    Map<String, dynamic> dbMap = {};
    for (int i = 0; i < 7; i++) {
      dbMap['${_days[i]}_earn'] = state.earns[i];
      dbMap['${_days[i]}_spend'] = state.spends[i];
    }

    await DatabaseHelper.instance.updateWeeklyStats(dbMap);
  }

  Future<void> resetCalculator() async {
    await DatabaseHelper.instance.deleteWeeklyStats();
    state = WeeklyCalcState(
      earns: List.filled(7, 0.0),
      spends: List.filled(7, 0.0),
      isLoading: false,
    );
  }
}
