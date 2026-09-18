import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/providers/mqtt_provider.dart';

/// Badge status MQTT ala StatusBadge.jsx web:
/// idle/connecting/connected/reconnecting/offline/error + last error.
class MqttStatusBadge extends ConsumerStatefulWidget {
  final bool compact;

  const MqttStatusBadge({super.key, this.compact = false});

  @override
  ConsumerState<MqttStatusBadge> createState() => _MqttStatusBadgeState();
}

class _MqttStatusBadgeState extends ConsumerState<MqttStatusBadge> {
  DateTime? _lastTap;

  void _retry() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inSeconds < 3) return;
    _lastTap = now;
    ref.read(mqttProvider.notifier).reconnect();
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = ref.watch(mqttProvider);
    final color = switch (mqtt.status) {
      'connected' => AppColors.statusActive,
      'connecting' || 'reconnecting' => AppColors.statusPending,
      'error' => AppColors.statusAlert,
      _ => AppColors.textMuted,
    };
    final label = switch (mqtt.status) {
      'connected' => 'MQTT Terhubung${mqtt.transport != null ? ' (${mqtt.transport})' : ''}',
      'connecting' => 'MQTT Menghubungkan...',
      'reconnecting' => 'MQTT Menyambung ulang...${mqtt.reconnectCount > 0 ? ' (#${mqtt.reconnectCount})' : ''}',
      'offline' => 'MQTT Offline${mqtt.reconnectCount > 0 ? ' (#${mqtt.reconnectCount})' : ''}',
      'error' => 'MQTT Error',
      _ => 'MQTT Idle',
    };
    final detail = mqtt.status == 'offline' && mqtt.lastError != null
        ? '$label — ${mqtt.lastError}'
        : (mqtt.status == 'reconnecting' && mqtt.lastError != null
            ? '$label — ${mqtt.lastError}'
            : (mqtt.statusSensor != null
                ? '$label · Sensor ${mqtt.statusSensor}'
                : label));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Tooltip(
            message: detail,
            child: Text(
              detail,
              style: TextStyle(
                fontSize: widget.compact ? 11 : 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: _retry,
          child: const Icon(Icons.refresh, size: 14, color: AppColors.primaryTeal),
        ),
      ],
    );
  }
}
