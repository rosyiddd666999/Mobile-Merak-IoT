import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils/date_formatter.dart';

/// Label field standar — gantikan `Widget _label(String)` identik di 6 form.
class AppLabel extends StatelessWidget {
  final String text;

  const AppLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Text field standar dengan label di atas + gap 16 di bawah.
/// Paksa validator dari `validators.dart` agar tidak inline `Wajib diisi`.
class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final String? hint;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLabel(label),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: hint != null ? InputDecoration(hintText: hint) : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Field tanggal standar: InkWell + InputDecorator + ikon kalender.
/// Gantikan duplikat `_pickDate` + `InputDecorator` di 5 form.
class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppLabel(label),
        InkWell(
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Text(formatDate(value.toIso8601String())),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Tombol simpan standar dengan spinner — gantikan
/// `ElevatedButton.icon(Simpan)+CircularProgressIndicator` x6.
class SaveButton extends StatelessWidget {
  final bool isSaving;
  final bool isEdit;
  final VoidCallback? onPressed;

  const SaveButton({super.key, required this.isSaving, this.isEdit = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: isSaving ? null : onPressed,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.save),
          label: Text(isEdit ? 'Simpan Perubahan' : 'Simpan'),
        ),
      ],
    );
  }
}
