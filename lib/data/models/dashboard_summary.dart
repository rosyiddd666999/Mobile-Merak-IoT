import 'incubator_status.dart';

class DashboardSummary {
  final int totalTelurAktif;
  final int totalAnakanBulanIni;
  final IncubatorStatus? inkubatorStatus;
  final FinanceSummary? financeSummary;
  // true bila dirakit lokal dari endpoint LIVE (summary backend 404).
  final bool isLocal;

  DashboardSummary({
    required this.totalTelurAktif,
    required this.totalAnakanBulanIni,
    this.inkubatorStatus,
    this.financeSummary,
    this.isLocal = false,
  });

  factory DashboardSummary.fromJson(dynamic json) {
    final map = json is Map<String, dynamic> ? json : <String, dynamic>{};
    Map<String, dynamic>? statusMap;
    final rawStatus = map['inkubator_status'];
    if (rawStatus is Map<String, dynamic>) statusMap = rawStatus;
    IncubatorStatus? status;
    if (statusMap != null) {
      try {
        status = IncubatorStatus.fromJson(statusMap);
      } catch (_) {
        status = null;
      }
    }
    FinanceSummary? finance;
    final rawFinance = map['finance_summary'];
    if (rawFinance is Map<String, dynamic>) {
      try {
        finance = FinanceSummary.fromJson(rawFinance);
      } catch (_) {
        finance = null;
      }
    }
    return DashboardSummary(
      totalTelurAktif: ((map['total_telur_aktif'] ?? map['total_telur'] ?? 0) as num).toInt(),
      totalAnakanBulanIni: ((map['total_anakan_bulan_ini'] ?? map['total_anakan'] ?? 0) as num).toInt(),
      inkubatorStatus: status,
      financeSummary: finance,
    );
  }
}

class FinanceSummary {
  final double totalPemasukan;
  final double totalPengeluaran;
  final double saldo;

  FinanceSummary({
    required this.totalPemasukan,
    required this.totalPengeluaran,
    required this.saldo,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) => FinanceSummary(
    totalPemasukan: (json['total_pemasukan'] as num?)?.toDouble() ?? 0,
    totalPengeluaran: (json['total_pengeluaran'] as num?)?.toDouble() ?? 0,
    saldo: (json['saldo'] as num?)?.toDouble() ?? 0,
  );
}
