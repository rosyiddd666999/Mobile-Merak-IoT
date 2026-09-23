/// Route terpusat — gantikan string '/breeders/$id' tersebar di app+list+card.
class AppRoutes {
  const AppRoutes._();

  static const dashboard = '/dashboard';
  static const incubator = '/incubator';
  static const breeders = '/breeders';
  static const eggs = '/eggs';
  static const chicks = '/chicks';
  static const sales = '/sales';
  static const finance = '/finance';
  static const users = '/users';
  static const alerts = '/alerts';
  static const cctv = '/cctv';
  static const profile = '/profile';
  static const about = '/about';
  static const login = '/login';

  static String breederDetail(String id) => '$breeders/$id';
  static String eggDetail(String id) => '$eggs/$id';
  static String chickDetail(String id) => '$chicks/$id';
  static String saleDetail(String id) => '$sales/$id';
  static String financeDetail(String id) => '$finance/$id';
  static String userDetail(String id) => '$users/$id';

  static const breederNew = '$breeders/new';
  static const eggNew = '$eggs/new';
  static const chickNew = '$chicks/new';
  static const saleNew = '$sales/new';
  static const financeNew = '$finance/new';
  static const userNew = '$users/new';
}
