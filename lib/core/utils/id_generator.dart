String nextId(List<String> existingIds, String prefix, {int padWidth = 3}) {
  final regex = RegExp(r'(\d+)$');
  int maxNum = 0;
  for (final id in existingIds) {
    final m = regex.firstMatch(id);
    if (m != null) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n > maxNum) maxNum = n;
    }
  }
  return '$prefix${(maxNum + 1).toString().padLeft(padWidth, '0')}';
}
