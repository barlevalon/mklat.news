class ShelterTimeFormatter {
  const ShelterTimeFormatter();

  String? format(int? shelterTimeSec) {
    if (shelterTimeSec == null) return null;
    if (shelterTimeSec == 0) return 'מיידי';
    if (shelterTimeSec < 60) return '$shelterTimeSec שניות';
    if (shelterTimeSec == 60) return 'דקה';
    if (shelterTimeSec == 90) return 'דקה וחצי';
    if (shelterTimeSec >= 120) {
      final minutes = shelterTimeSec ~/ 60;
      return '$minutes דקות';
    }

    final minutes = shelterTimeSec ~/ 60;
    final seconds = shelterTimeSec % 60;
    if (seconds == 0) return '$minutes דקות';
    return '$minutes:${seconds.toString().padLeft(2, '0')} דקות';
  }
}
