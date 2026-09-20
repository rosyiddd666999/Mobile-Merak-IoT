import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
