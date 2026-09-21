/// Margin toleransi monitoring: suhu ±0,2°C, kelembapan ±2%.
/// Nilai di dalam margin dianggap normal — status hijau dan alert
/// hanya muncul bila MELAMPAUI margin (mis. batas 37,5–38,5:
/// 37,3/38,7 aman, 37,2/38,8 tidak).
class AlertMargins {
  const AlertMargins._();

  static const double suhu = 0.2;
  static const double kelembapan = 2.0;
}
