import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Baca env dengan aman: kembalikan [fallback] bila dotenv belum
/// diinisialisasi (mis. `.env` tidak ada di assets) atau baca gagal.
/// Tanpa guard ini, `dotenv.get` melempar `NotInitializedError` saat
/// `dotenv.load()` gagal — persis crash login yang pernah terjadi.
String envOr(String key, {String fallback = ''}) {
  try {
    if (!dotenv.isInitialized) return fallback;
    return dotenv.get(key, fallback: fallback);
  } catch (_) {
    return fallback;
  }
}
