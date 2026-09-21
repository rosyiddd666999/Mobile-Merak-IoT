import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/api_error.dart';
import '../../data/services/upload_service.dart';
import 'app_form.dart';
import 'app_photo.dart';

/// Hasil pilihan foto: URL server (bila sudah terupload) atau file lokal
/// yang menunggu upload saat Simpan.
class PickedPhoto {
  final String? url;
  final File? file;
  final String? objectKey;

  const PickedPhoto({this.url, this.file, this.objectKey});

  bool get isEmpty => (url == null || url!.isEmpty) && file == null;
}

/// Pilih foto dari galeri/kamera + pratinjau. Upload dilakukan pemilik form
/// via [UploadService] saat Simpan (agar gagal upload = save dibatalkan).
class AppPhotoPicker extends ConsumerStatefulWidget {
  final String label;
  final String? initialUrl;
  final UploadFolder folder;
  final ValueChanged<PickedPhoto> onChanged;

  const AppPhotoPicker({
    super.key,
    this.label = 'Foto',
    this.initialUrl,
    required this.folder,
    required this.onChanged,
  });

  @override
  ConsumerState<AppPhotoPicker> createState() => _AppPhotoPickerState();
}

class _AppPhotoPickerState extends ConsumerState<AppPhotoPicker> {
  final _picker = ImagePicker();
  File? _file;
  bool _removed = false;

  String? get _url => _removed ? null : widget.initialUrl;

  void _emit() => widget.onChanged(PickedPhoto(url: _url, file: _file));

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      final file = File(picked.path);
      final err = UploadService.validate(file);
      if (err != null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(err)));
        }
        return;
      }
      setState(() {
        _file = file;
        _removed = false;
      });
      _emit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: ${friendlyApiError(e)}')),
        );
      }
    }
  }

  void _clear() {
    setState(() {
      _file = null;
      _removed = true;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLabel(widget.label),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _preview(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Galeri'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Kamera'),
                  ),
                  if (_file != null || (_url?.isNotEmpty == true)) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      label: const Text('Hapus',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _preview() {
    if (_file != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_file!, width: 96, height: 96, fit: BoxFit.cover),
      );
    }
    return AppPhotoBox(
      size: 96,
      url: _url,
      fallback: const Icon(Icons.image_outlined,
          size: 40, color: Colors.grey),
    );
  }
}
