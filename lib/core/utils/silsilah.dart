// Helper ID silsilah - mirror ringan dari fastapi-backend/app/silsilah.py.
// Format: Breeder F0 JB{NN}/BB{NN}, Telur/anak {J}{B}-{NN}, Anakan {Telur}-C{NN}.

final _f0Regex = RegExp(r'^(JB|BB)(\d{2,})$');
final _anakRegex = RegExp(r'^(.+)-(\d{2,})$');
final _chickRegex = RegExp(r'^(.+)-C(\d{2,})$');

bool isLegacyId(String id) {
  if (id.startsWith('MRK-') || id.startsWith('EGG-') || id.startsWith('CHK-')) return true;
  if (_chickRegex.hasMatch(id)) return false;
  if (_anakRegex.hasMatch(id)) return false;
  if (_f0Regex.hasMatch(id)) return false;
  return true;
}

String pad2(int n) => n.toString().padLeft(2, '0');

String prefixTelur(String jantanId, String betinaId) => '$jantanId$betinaId-';

String prefixChick(String eggId) => '$eggId-C';

String prefixBreederF0(String jenisKelamin) => jenisKelamin == 'jantan' ? 'JB' : 'BB';

int _suffixAnak(String id) {
  final m = _anakRegex.firstMatch(id);
  if (m == null) return 0;
  // Jangan tangkap -C{NN} sebagai anak biasa.
  if (_chickRegex.hasMatch(id)) return 0;
  return int.tryParse(m.group(2)!) ?? 0;
}

int _suffixChick(String id) {
  final m = _chickRegex.firstMatch(id);
  if (m == null) return 0;
  return int.tryParse(m.group(2)!) ?? 0;
}

int _suffixF0(String id, String kode) {
  final m = _f0Regex.firstMatch(id);
  if (m == null || m.group(1) != kode) return 0;
  return int.tryParse(m.group(2)!) ?? 0;
}

/// Nomor berikutnya per pasangan induk (telur / breeder anak).
int nextNomorPasangan(List<String> existingIds, String jantanId, String betinaId) {
  final prefix = '$jantanId$betinaId-';
  var maxN = 0;
  for (final id in existingIds) {
    if (!id.startsWith(prefix)) continue;
    if (_chickRegex.hasMatch(id)) continue;
    final n = _suffixAnak(id);
    if (n > maxN) maxN = n;
  }
  return maxN + 1;
}

/// Nomor berikutnya per telur untuk anakan (-C{NN}).
int nextNomorChick(List<String> existingIds, String eggId) {
  final prefix = '$eggId-C';
  var maxN = 0;
  for (final id in existingIds) {
    if (!id.startsWith(prefix)) continue;
    final n = _suffixChick(id);
    if (n > maxN) maxN = n;
  }
  return maxN + 1;
}

/// Nomor berikutnya untuk Breeder F0 per kode JB/BB.
int nextNomorF0(List<String> existingIds, String jenisKelamin) {
  final kode = prefixBreederF0(jenisKelamin);
  var maxN = 0;
  for (final id in existingIds) {
    final n = _suffixF0(id, kode);
    if (n > maxN) maxN = n;
  }
  return maxN + 1;
}

/// Ambil suffix "-NN" dari ID telur/anak untuk mode edit.
String suffixOfAnak(String id) {
  final m = _anakRegex.firstMatch(id);
  if (m == null || _chickRegex.hasMatch(id)) return '';
  return m.group(2) ?? '';
}

/// Ambil suffix "C{NN}" dari ID anakan untuk mode edit.
String suffixOfChick(String id) {
  final m = _chickRegex.firstMatch(id);
  if (m == null) return '';
  return 'C${m.group(2)}';
}

/// Validasi prefix client-side sebelum kirim (pesan mirip backend 422).
String? validateTelurId(String id, String jantanId, String betinaId) {
  if (isLegacyId(id)) return null;
  final prefix = prefixTelur(jantanId, betinaId);
  if (!id.startsWith(prefix)) return 'ID telur harus diawali $prefix{NN}';
  if (!_anakRegex.hasMatch(id) || _chickRegex.hasMatch(id)) {
    return 'ID telur harus format $prefix{NN} (contoh ${prefix}01)';
  }
  return null;
}

String? validateChickId(String id, String eggId) {
  if (isLegacyId(id)) return null;
  final prefix = prefixChick(eggId);
  if (!id.startsWith(prefix)) return 'ID anakan harus diawali $prefix{NN}';
  if (!_chickRegex.hasMatch(id)) return 'ID anakan harus format $prefix{NN} (contoh ${prefix}01)';
  return null;
}
