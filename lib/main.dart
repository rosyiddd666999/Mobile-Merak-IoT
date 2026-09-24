import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // .env opsional (dev lokal saja, tidak dibundle di release).
  // Konfigurasi utama via --dart-define; kegagalan load diabaikan.
  try {
    await dotenv.load();
  } catch (_) {
    // Abaikan: AppConstants akan fallback ke AppConfig (dart-define).
  }
  // Data simbol tanggal id_ID untuk DateFormat ber-locale (PDF Arus Kas, dsb).
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {
    // Abaikan: pemakaian sudah punya fallback manual.
  }
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const ProviderScope(child: MerakApp()));
}

class MerakApp extends ConsumerWidget {
  const MerakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Merak Ndalem Kerto - MerakNK',
      theme: appTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
