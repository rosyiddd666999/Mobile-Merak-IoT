import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../data/models/auth_response.dart';
import '../../data/providers/api_client_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../shared/partner_logos.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  bool _resolved = false;
  bool _ready = false;
  String? _pendingRoute; // '/dashboard' | '/login' — dieksekusi saat waktunya tiba
  late final AnimationController _anim;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _loadingFade;
  late final Animation<double> _partnersFade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _anim,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.0, 0.35)),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.25, 0.6, curve: Curves.easeOut)),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.25, 0.6)),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.4, 0.75, curve: Curves.easeOut)),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.4, 0.75)),
    );
    _loadingFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.65, 1.0)),
    );
    _partnersFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _anim, curve: const Interval(0.60, 0.85)),
    );
    _anim.forward();
    _scheduleTimeout();
    _preload();
  }

  Future<void> _preload() async {
    // Isi apiKeyProvider/jwtTokenProvider sebelum request pertama (MOBILE.md §7.1).
    await preloadAuthState(ref);
    if (!mounted || _resolved) return;
    final token = ref.read(jwtTokenProvider);
    if (token != null && token.isNotEmpty) {
      await ref.read(authProvider.notifier).fetchMe();
    }
  }

  void _scheduleTimeout() {
    // Waktu tampil MINIMUM 5 detik agar animasi + logo mitra selesai —
    // navigasi (login/dashboard) tidak boleh memotong splash.
    _timer = Timer(const Duration(milliseconds: 5000), () {
      if (!mounted) return;
      _ready = true;
      _flushPending();
    });
  }

  /// Jalankan rute tertunda bila waktu minimum terpenuhi.
  void _flushPending() {
    if (!_ready || _resolved || !mounted) return;
    final route = _pendingRoute;
    if (route == null) {
      // Timeout tanpa keputusan auth: default ke login.
      _resolved = true;
      context.go('/login');
      return;
    }
    _resolved = true;
    context.go(route);
  }

  /// Catat keputusan rute; eksekusi ditahan sampai timer 5 detik bunyi.
  void _decide(String route) {
    _pendingRoute = route;
    _flushPending();
  }

  void _goTo(AuthResponse? auth) {
    if (!mounted || _resolved) return;
    if (auth != null) {
      ref.read(authProvider.notifier).fetchMe();
      _decide('/dashboard');
    } else {
      _decide('/login');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (prev, next) {
      next.whenOrNull(data: _goTo);
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                FadeTransition(
                  opacity: _partnersFade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kerjasama',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white60,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const PartnerLogos(
                        size: 56,
                        wide: true,
                        alignment: MainAxisAlignment.spaceBetween,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: 104,
                              height: 104,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Text(
                              'Media Edukasi Kampung Merak Gentan Hijau Berseri',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _subtitleFade,
                          child: SlideTransition(
                            position: _subtitleSlide,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Kerjasama',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white60,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'PT Pertamina Patra Niaga FT Madiun',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white70,
                                        letterSpacing: 0.5,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _loadingFade,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Memuat...',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white60,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
