import '../core/theme.dart';

/// Satu-satunya tempat mapping string backend -> (label, AppStatus).
/// Gantikan belasan `switch (s.toLowerCase())` di card/detail/list.
class StatusMapper {
  const StatusMapper._();

  static (String, AppStatus) breeder(String s) {
    switch (s) {
      case 'breeding':
        return ('Aktif', AppStatus.active);
      case 'resting':
        return ('Istirahat', AppStatus.pending);
      case 'ready_for_sale':
        return ('Siap Jual', AppStatus.ready);
      default:
        return (s.isEmpty ? '-' : s, AppStatus.neutral);
    }
  }

  static (String, AppStatus) eggFertility(String s) {
    switch (s.toLowerCase()) {
      case 'fertil':
        return ('Fertil', AppStatus.active);
      case 'infertil':
        return ('Infertil', AppStatus.alert);
      case 'belum dicek':
        return ('Belum dicek', AppStatus.pending);
      default:
        return (s.isEmpty ? '-' : s, s.isEmpty ? AppStatus.neutral : AppStatus.pending);
    }
  }

  static (String, AppStatus) eggOutcome(String s) {
    switch (s.toLowerCase()) {
      case 'menetas':
        return ('Menetas', AppStatus.ready);
      case 'gagal':
        return ('Gagal', AppStatus.alert);
      case 'proses':
        return ('Proses', AppStatus.pending);
      default:
        return (s.isEmpty ? '-' : s, s.isEmpty ? AppStatus.neutral : AppStatus.pending);
    }
  }

  static (String, AppStatus) chick(String s) {
    switch (s.toLowerCase()) {
      case 'newborn':
        return ('Baru', AppStatus.ready);
      case 'growing':
        return ('Tumbuh', AppStatus.active);
      case 'ready_for_sale':
        return ('Jual', AppStatus.pending);
      case 'sold':
        return ('Terjual', AppStatus.neutral);
      default:
        return (s.isEmpty ? '-' : s, AppStatus.neutral);
    }
  }

  static (String, AppStatus) sale(String s) {
    switch (s.toLowerCase()) {
      case 'lunas':
        return (s, AppStatus.active);
      case 'dp':
      case 'booking':
      case 'proses':
        return (s, AppStatus.pending);
      case '':
        return ('-', AppStatus.neutral);
      default:
        return (s, AppStatus.pending);
    }
  }

  static (String, AppStatus) userRole(String role) {
    return role == 'pemilik' ? ('Pemilik', AppStatus.ready) : ('Staff', AppStatus.pending);
  }

  static (String, AppStatus) financeType(String tipe) {
    return tipe.toLowerCase() == 'pemasukan'
        ? (tipe, AppStatus.active)
        : (tipe, AppStatus.alert);
  }
}

/// Role pengguna terpusat — gantikan string 'pemilik'/'staff' tersebar.
enum UserRole { pemilik, staff }

extension UserRoleX on UserRole {
  static UserRole fromString(String s) => s == 'pemilik' ? UserRole.pemilik : UserRole.staff;
  String get value => this == UserRole.pemilik ? 'pemilik' : 'staff';
  String get label => this == UserRole.pemilik ? 'Pemilik' : 'Staff';
}
