import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Jenis kegagalan request — satu-satunya klasifikasi di app.
enum FailureKind {
  sessionExpired, // 401: token/API key salah → wajib login ulang, tanpa retry
  forbidden, // 403: peran tak cukup
  notFound, // 404: data hilang di server
  validation, // 422/400: server menolak input
  server, // 500/502/503: salah backend
  network, // tanpa koneksi / DNS / sertifikat
  timeout, // connect/receive/send timeout
  unknown, // lainnya
}

/// Abstraksi kondisi error seluruh request non-200.
/// Pakai: `AppFailure.from(e, action: 'memuat data indukan')`.
class AppFailure {
  final FailureKind kind;
  final String action;
  final String? detail;

  const AppFailure._(this.kind, this.action, [this.detail]);

  /// Pesan spesifik: operasi apa + kenapa + apa yang harus dilakukan.
  String get message {
    const prefix = 'Gagal';
    switch (kind) {
      case FailureKind.sessionExpired:
        return '$prefix $action: sesi berakhir, silakan masuk kembali';
      case FailureKind.forbidden:
        return '$prefix $action: akun Anda tidak punya akses';
      case FailureKind.notFound:
        return '$prefix $action: data tidak ditemukan di server';
      case FailureKind.validation:
        return detail != null && detail!.isNotEmpty
            ? '$prefix $action: $detail'
            : '$prefix $action: input ditolak server';
      case FailureKind.server:
        return '$prefix $action: server bermasalah, coba lagi nanti';
      case FailureKind.network:
        return '$prefix $action: tidak terhubung ke server';
      case FailureKind.timeout:
        return '$prefix $action: waktu habis, periksa koneksi Anda';
      case FailureKind.unknown:
        return detail != null && detail!.isNotEmpty
            ? '$prefix $action: $detail'
            : '$prefix $action: terjadi kesalahan tak terduga';
    }
  }

  /// True hanya untuk sessionExpired — UI wajib tampilkan tombol
  /// "Masuk Kembali", bukan "Coba Lagi".
  bool get needsLogin => kind == FailureKind.sessionExpired;

  /// Retry sia-sia untuk sesi berakhir & validasi yang butuh perbaikan input.
  bool get retryable =>
      kind != FailureKind.sessionExpired &&
      kind != FailureKind.validation;

  IconData get icon {
    switch (kind) {
      case FailureKind.sessionExpired:
        return Icons.lock_outline;
      case FailureKind.forbidden:
        return Icons.block_outlined;
      case FailureKind.notFound:
        return Icons.search_off_outlined;
      case FailureKind.validation:
        return Icons.rule_outlined;
      case FailureKind.server:
        return Icons.cloud_off_outlined;
      case FailureKind.network:
        return Icons.wifi_off_outlined;
      case FailureKind.timeout:
        return Icons.timer_off_outlined;
      case FailureKind.unknown:
        return Icons.error_outline;
    }
  }

  static AppFailure from(Object error, {String action = 'memproses data'}) {
    // Pesan spesifik dari service — hormati apa adanya.
    if (error is StateError && error.message.toString().isNotEmpty) {
      return AppFailure._(FailureKind.unknown, action, error.message.toString());
    }
    if (error is FormatException) {
      return AppFailure._(FailureKind.unknown, action, error.message);
    }
    if (error is DioException) {
      final status = error.response?.statusCode;
      switch (status) {
        case 401:
          return AppFailure._(FailureKind.sessionExpired, action);
        case 403:
          return AppFailure._(FailureKind.forbidden, action);
        case 404:
          return AppFailure._(FailureKind.notFound, action);
        case 400:
        case 422:
          return AppFailure._(
            FailureKind.validation,
            action,
            _serverDetail(error),
          );
        case 500:
        case 502:
        case 503:
          return AppFailure._(FailureKind.server, action);
        default:
          break;
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.transformTimeout:
          return AppFailure._(FailureKind.timeout, action);
        case DioExceptionType.connectionError:
          return AppFailure._(FailureKind.network, action);
        case DioExceptionType.badCertificate:
          return AppFailure._(
            FailureKind.network,
            action,
            'sertifikat keamanan server tidak valid',
          );
        case DioExceptionType.cancel:
          return AppFailure._(FailureKind.unknown, action, 'dibatalkan');
        case DioExceptionType.badResponse:
          return AppFailure._(
            FailureKind.unknown,
            action,
            status != null ? 'kode $status' : null,
          );
        case DioExceptionType.unknown:
          return AppFailure._(FailureKind.network, action);
      }
    }
    return AppFailure._(FailureKind.unknown, action);
  }

  /// Ambil pesan validasi dari body server bila ada.
  static String? _serverDetail(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        for (final k in ['message', 'detail', 'error']) {
          final v = data[k];
          if (v is String && v.isNotEmpty) return v;
        }
      } else if (data is String && data.isNotEmpty) {
        return data;
      }
    } catch (_) {}
    return null;
  }
}
