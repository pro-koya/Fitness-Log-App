/// Formats a duration (in seconds) for goal display: "X分Y秒" / "X min Y sec".
String formatDurationForGoal(int totalSeconds, String language) {
  final min = totalSeconds ~/ 60;
  final sec = totalSeconds % 60;
  if (language == 'ja') {
    return '${min}分${sec}秒';
  }
  return '$min min $sec sec';
}
