import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils/api_error.dart';
import 'design_kit.dart';
import 'loading_widget.dart';
import 'error_widget.dart';

/// Gantikan pola `async.when(loading: LoadingWidget, error: AppErrorWidget,
/// data: ...)` yang diulang ~15x di list/detail/form-edit.
/// [isEmpty] opsional: bila true tampilkan [EmptyState] alih-alih dataBuilder.
class AsyncStateView<T> extends StatelessWidget {
  final AsyncValue<T> async;
  final String loadingMessage;
  final IconData emptyIcon;
  final String emptyMessage;
  final Widget Function(T data) dataBuilder;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;

  const AsyncStateView({
    super.key,
    required this.async,
    required this.dataBuilder,
    this.loadingMessage = 'Memuat data...',
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyMessage = 'Belum ada data.',
    this.onRetry,
    this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => LoadingWidget(message: loadingMessage),
      error: (e, _) => AppErrorWidget(
        message: friendlyApiError(e),
        onRetry: onRetry,
      ),
      data: (data) {
        if (isEmpty?.call(data) == true) {
          return EmptyState(icon: emptyIcon, message: emptyMessage);
        }
        return dataBuilder(data);
      },
    );
  }
}

/// Chip filter standar — gantikan builder `chip()` di breeders vs sales.
class AppFilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        count != null ? '$label ($count)' : label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : AppColors.textDark,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.darkCard,
      onSelected: (_) => onTap(),
    );
  }
}
