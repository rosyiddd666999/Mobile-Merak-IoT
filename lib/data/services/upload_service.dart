import 'dart:io';

import 'package:dio/dio.dart';

/// Folder upload yang diizinkan backend (`POST /api/storage/upload`).
enum UploadFolder {
  breeders('breeders-images'),
  chicks('chicks-images'),
  profile('profile-images');

  final String value;
  const UploadFolder(this.value);
}

/// Hasil upload: `url` absolut siap render, `objectKey` untuk hapus/migrasi.
class UploadResult {
  final String url;
  final String? objectKey;

  const UploadResult({required this.url, this.objectKey});
}

/// Upload foto perangkat ke Minio via backend (maks 5MB, dicek client juga).
class UploadService {
  UploadService(this._dio);
  final Dio _dio;

  static const maxBytes = 5 * 1024 * 1024;

  static const _allowedExt = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  /// Validasi lokal sebelum upload. Return pesan error atau null bila OK.
  static String? validate(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    if (!_allowedExt.contains(ext)) {
      return 'Format harus JPG/PNG/WebP/GIF';
    }
    final size = file.lengthSync();
    if (size > maxBytes) {
      return 'Ukuran maksimal 5MB (saat ini ${(size / 1048576).toStringAsFixed(1)}MB)';
    }
    return null;
  }

  Future<UploadResult> uploadPhoto(
    File file,
    UploadFolder folder, {
    ProgressCallback? onProgress,
  }) async {
    final err = validate(file);
    if (err != null) throw ArgumentError(err);
    final fileName = file.path.split('/').last;
    final form = FormData.fromMap({
      'folder': folder.value,
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final res = await _dio.post(
      '/api/storage/upload',
      data: form,
      onSendProgress: onProgress,
    );
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Respons upload tidak dikenal');
    }
    final url = (data['url'] ?? '') as String;
    if (url.isEmpty) throw const FormatException('URL upload kosong');
    return UploadResult(url: url, objectKey: data['object_key'] as String?);
  }

  /// Ambil object_key dari URL absolut Minio untuk keperluan hapus:
  /// `https://host/merak-storage/<folder>/<uuid>.jpg` -> `<folder>/<uuid>.jpg`.
  /// Return null bila format tak dikenal (jangan hapus sembarang).
  static String? objectKeyFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.pathSegments.length < 3) return null;
    return uri.pathSegments.sublist(1).join('/');
  }

  /// Hapus file milik sesi ini (mis. diganti/dibatalkan). Gagal = abaikan.
  Future<void> deletePhoto(String objectKey) async {
    try {
      await _dio.delete(
        '/api/storage/delete',
        queryParameters: {'object_key': objectKey},
      );
    } catch (_) {}
  }
}
