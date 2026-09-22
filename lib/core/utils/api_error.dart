import 'package:dio/dio.dart';

/// Kompatibilitas snackbars lama (pesan tanpa konteks operasi).
/// Kode baru sebaiknya pakai `AppFailure.from(e, action: ...)` langsung
/// agar pesan menyebut operasi yang gagal.
String friendlyApiError(Object error, {String action = 'memproses data'}) {
  if (error is StateError && error.message.toString().isNotEmpty) {
    return error.message.toString();
  }
  if (error is DioException) {
    final status = error.response?.statusCode;
    switch (status) {
      case 401:
        return 'Sesi berakhir. Silakan masuk kembali';
      case 404:
        return 'Data belum tersedia';
      case 500:
        return 'Server sedang bermasalah. Coba lagi nanti';
      case 502:
      case 503:
        return 'Server sedang sibuk. Coba lagi nanti';
      default:
        break;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return 'Waktu permintaan habis. Periksa koneksi Anda';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server';
      case DioExceptionType.badResponse:
        return status != null ? 'Terjadi kesalahan (kode $status)' : 'Terjadi kesalahan pada server';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan';
      case DioExceptionType.badCertificate:
        return 'Sertifikat keamanan server tidak valid';
      case DioExceptionType.unknown:
        return 'Terjadi kesalahan tak terduga';
    }
  }
  return 'Terjadi kesalahan tak terduga';
}
