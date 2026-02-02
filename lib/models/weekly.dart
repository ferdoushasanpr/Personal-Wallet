class WeeklyCalcState {
  final List<double> earns;
  final List<double> spends;
  final bool isLoading;

  WeeklyCalcState({
    required this.earns,
    required this.spends,
    this.isLoading = false,
  });

  // Helper to create a copy of the state with updated values
  WeeklyCalcState copyWith({
    List<double>? earns,
    List<double>? spends,
    bool? isLoading,
  }) {
    return WeeklyCalcState(
      earns: earns ?? this.earns,
      spends: spends ?? this.spends,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
