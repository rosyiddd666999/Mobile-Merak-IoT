import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Peta slot inkubator 1-100 ala booking kursi.
/// Terisi = ada telur berstatus "Proses" (Menetas/Gagal dianggap sudah keluar).
/// [occupiedSlots]: slot yang terisi (di luar milik sendiri saat mode edit).
/// [initialSlot]: slot awal (milik sendiri / draft).
class SlotPicker extends StatelessWidget {
  final Set<int> occupiedSlots;
  final int? initialSlot;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;

  const SlotPicker({
    super.key,
    required this.occupiedSlots,
    required this.initialSlot,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      initialValue: initialSlot,
      validator: validator ?? (_) => null,
      builder: (field) {
        final selected = field.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _legend(AppColors.primaryTeal, 'Dipilih'),
                const SizedBox(width: 12),
                _legend(AppColors.textMuted, 'Terisi'),
                const SizedBox(width: 12),
                _legend(Colors.white, 'Kosong', bordered: true),
                const Spacer(),
                Text(
                  selected != null ? 'Slot: $selected' : 'Belum pilih',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              itemCount: 100,
              itemBuilder: (_, i) {
                final slot = i + 1;
                final occupied = occupiedSlots.contains(slot);
                final isSelected = selected == slot;
                return _SlotCell(
                  slot: slot,
                  occupied: occupied,
                  selected: isSelected,
                  onTap: occupied
                      ? null
                      : () {
                          field.didChange(slot);
                          onChanged(slot);
                        },
                );
              },
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _legend(Color color, String label, {bool bordered = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: bordered ? Border.all(color: AppColors.divider) : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _SlotCell extends StatelessWidget {
  final int slot;
  final bool occupied;
  final bool selected;
  final VoidCallback? onTap;

  const _SlotCell({
    required this.slot,
    required this.occupied,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.primaryTeal
        : occupied
            ? AppColors.textMuted.withValues(alpha: 0.35)
            : Colors.white;
    final fg = selected
        ? Colors.white
        : occupied
            ? AppColors.textMuted
            : AppColors.textDark;
    final content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? AppColors.primaryTeal : AppColors.divider,
        ),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '$slot',
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
    if (onTap == null) {
      return Tooltip(message: 'Slot $slot terisi', child: content);
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: content,
    );
  }
}
