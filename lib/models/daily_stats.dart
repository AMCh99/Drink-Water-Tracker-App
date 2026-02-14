class DailyStats {
  final DateTime date;
  final int totalMl;
  final int goalMl;

  DailyStats({required this.date, required this.totalMl, required this.goalMl});

  /// Czy ten dzień jest w przyszłości (brak danych)
  bool get isFuture => totalMl < 0;

  bool get goalReached => !isFuture && totalMl >= goalMl;

  double get progress =>
      isFuture ? 0.0 : (goalMl > 0 ? (totalMl / goalMl).clamp(0.0, 1.0) : 0.0);

  double get percentage => progress * 100;
}
