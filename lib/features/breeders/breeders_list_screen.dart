import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils/api_error.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/breeder.dart';
import '../../data/models/chick.dart';
import '../../data/models/egg.dart';
import '../../data/providers/breeders_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/chicks_provider.dart';
import '../../data/providers/eggs_provider.dart';
import '../../data/providers/sales_provider.dart';
import '../../shared/design_kit.dart';
import '../../shared/loading_widget.dart';
import '../../shared/error_widget.dart';
import '../../shared/root_app_bar.dart';
import 'widgets/breeder_card.dart';

class BreedersListScreen extends ConsumerStatefulWidget {
  const BreedersListScreen({super.key});

  @override
  ConsumerState<BreedersListScreen> createState() => _BreedersListScreenState();
}

class _BreedersListScreenState extends ConsumerState<BreedersListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _genFilter = 'Semua'; // Semua | F0 | F1
  String _statusFilter = 'Semua'; // Semua | Aktif | Istirahat | Siap Jual

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final breedersAsync = ref.watch(breedersListProvider);
    final eggsAsync = ref.watch(eggsListProvider);
    final chicksAsync = ref.watch(chicksListProvider);
    final salesAsync = ref.watch(salesListProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = user != null;

    return Scaffold(
      appBar: const RootAppBar(title: 'Indukan'),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push('/breeders/new'),
              backgroundColor: AppColors.darkCard,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(eggsListProvider);
          ref.invalidate(chicksListProvider);
          ref.invalidate(salesListProvider);
          ref.invalidate(breedersListProvider);
          await ref.read(breedersListProvider.future);
        },
        child: breedersAsync.when(
          loading: () => const LoadingWidget(message: 'Memuat data indukan...'),
          error: (err, _) => AppErrorWidget(
            message: friendlyApiError(err),
            onRetry: () => ref.refresh(breedersListProvider),
          ),
          data: (breeders) {
            final sales = salesAsync.valueOrNull ?? const [];
            final soldIds = {
              for (final s in sales)
                if (s.status.toLowerCase() == 'lunas' && s.referensiId.isNotEmpty)
                  s.referensiId,
            };
            final filtered = _apply(breeders)
              ..sort((a, b) =>
                  ((soldIds.contains(a.id) ? 1 : 0) - (soldIds.contains(b.id) ? 1 : 0)));
            final eggs = eggsAsync.valueOrNull ?? const <Egg>[];
            final chicks = chicksAsync.valueOrNull ?? const <Chick>[];
            final stats = _statsFor(breeders, eggs, chicks);
            final names = {
              for (final b in breeders)
                b.id: (b.nama?.isNotEmpty == true ? b.nama! : b.id),
            };
            final latest = List<Egg>.of(eggs)
              ..sort((a, b) => b.tanggalMasuk.compareTo(a.tanggalMasuk));
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                _searchRow(canCreate),
                const SizedBox(height: 12),
                const CollapsibleBanner(
                  collapsedLabel: 'Analisis Kompatibilitas →',
                  title: 'Analisis Kompatibilitas',
                  body:
                      'Pasangan dengan varian dan generasi berbeda meningkatkan keragaman anakan. '
                      'Pilih indukan jantan dan betina dari daftar untuk melihat silsilahnya.',
                  icon: Icons.science_outlined,
                ),
                if (latest.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _LatestActivityCard(
                    eggs: latest.take(3).toList(),
                    names: names,
                    onOpen: (id) => context.push('/eggs/$id'),
                  ),
                ],
                const SizedBox(height: 12),
                _filterRow(breeders),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.pets_outlined,
                    message: 'Belum ada data di kategori ini',
                  )
                else
                  ...filtered.map(
                    (b) => BreederCard(
                      breeder: b,
                      stats: stats[b.id],
                      sold: soldIds.contains(b.id),
                      onTap: () => context.push('/breeders/${b.id}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Search full width + tombol tambah icon bulat (DESIGN.md §2.1).
  Widget _searchRow(bool canCreate) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Cari nama / ID...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        if (canCreate) ...[
          const SizedBox(width: 8),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.darkCard,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Tambah',
              onPressed: () => context.push('/breeders/new'),
            ),
          ),
        ],
      ],
    );
  }

  /// Satu baris filter: generasi + status, dipisah divider tipis.
  Widget _filterRow(List<Breeder> all) {
    int genCount(String g) => g == 'Semua'
        ? all.length
        : all.where((b) => b.generasi.toUpperCase().startsWith(g)).length;
    int statusCount(String o) => o == 'Semua'
        ? all.length
        : all.where((b) => _statusLabel(b.status) == o).length;
    Widget chip(String label, bool selected, VoidCallback onTap) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => setState(onTap),
          selectedColor: AppColors.darkCard,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textDark,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final g in ['Semua', 'F0', 'F1'])
            chip(
              g == 'Semua' ? 'Semua ${genCount(g)}' : '$g ${genCount(g)}',
              _genFilter == g,
              () => _genFilter = g,
            ),
          Container(
            width: 1,
            height: 24,
            color: AppColors.divider,
            margin: const EdgeInsets.only(right: 8),
          ),
          for (final o in ['Aktif', 'Istirahat', 'Siap Jual'])
            chip(
              '$o ${statusCount(o)}',
              _statusFilter == o,
              () => _statusFilter = _statusFilter == o ? 'Semua' : o,
            ),
        ],
      ),
    );
  }

  /// Statistik per indukan dari list telur/anakan (murni, testable).
  Map<String, BreederStats> _statsFor(
    List<Breeder> breeders,
    List<Egg> eggs,
    List<Chick> chicks,
  ) {
    final eggById = {for (final e in eggs) e.id: e};
    final map = <String, BreederStats>{};
    for (final b in breeders) {
      final mine = eggs
          .where((e) => e.indukJantanId == b.id || e.indukBetinaId == b.id)
          .toList();
      final checked = mine
          .where((e) => e.fertilitas == 'Fertil' || e.fertilitas == 'Infertil')
          .toList();
      final fertil = checked.where((e) => e.fertilitas == 'Fertil').length;
      final anakan = chicks.where((c) {
        final egg = eggById[c.eggId];
        return egg != null &&
            (egg.indukJantanId == b.id || egg.indukBetinaId == b.id);
      }).length;
      map[b.id] = BreederStats(
        totalTelur: mine.length,
        persentaseFertil: checked.isEmpty ? 0 : fertil * 100 / checked.length,
        jumlahAnakan: anakan,
      );
    }
    return map;
  }

  List<Breeder> _apply(List<Breeder> list) {
    return list.where((b) {
      if (_genFilter != 'Semua' &&
          !b.generasi.toUpperCase().startsWith(_genFilter)) {
        return false;
      }
      if (_statusFilter != 'Semua' && _statusLabel(b.status) != _statusFilter) {
        return false;
      }
      if (_query.isNotEmpty) {
        final hay = '${b.nama ?? ''} ${b.id}'.toLowerCase();
        if (!hay.contains(_query)) return false;
      }
      return true;
    }).toList();
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'breeding':
        return 'Aktif';
      case 'resting':
        return 'Istirahat';
      case 'ready_for_sale':
        return 'Siap Jual';
      default:
        return s;
    }
  }
}

/// Aktivitas terkini: 3 telur terbaru + nama pasangan induk.
class _LatestActivityCard extends StatelessWidget {
  final List<Egg> eggs;
  final Map<String, String> names;
  final ValueChanged<String> onOpen;

  const _LatestActivityCard({
    required this.eggs,
    required this.names,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aktivitas Terkini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < eggs.length; i++) ...[
              _eggRow(context, eggs[i]),
              if (i < eggs.length - 1)
                const Divider(height: 1, indent: 0, endIndent: 0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eggRow(BuildContext context, Egg egg) {
    final ayah = names[egg.indukJantanId] ?? egg.indukJantanId;
    final ibu = names[egg.indukBetinaId] ?? egg.indukBetinaId;
    final pair = (egg.indukJantanId.isEmpty && egg.indukBetinaId.isEmpty)
        ? '-'
        : '$ayah × $ibu';
    final fertil = egg.fertilitas;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.egg_outlined,
          size: 19,
          color: AppColors.primaryTeal,
        ),
      ),
      title: Text(
        egg.id,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$pair · ${egg.tanggalMasuk.isNotEmpty ? formatDate(egg.tanggalMasuk) : '-'}',
        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: StatusChip(
        label: fertil.isEmpty ? '-' : fertil,
        status: fertil == 'Fertil'
            ? AppStatus.active
            : fertil == 'Infertil'
            ? AppStatus.alert
            : AppStatus.pending,
      ),
      onTap: () => onOpen(egg.id),
    );
  }
}
