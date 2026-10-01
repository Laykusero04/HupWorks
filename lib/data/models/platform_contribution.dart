import 'package:equatable/equatable.dart';
import 'package:freelancer/core/constants/app_constants.dart';

class PlatformContribution extends Equatable {
  final String role;
  final int shiftsCompleted;
  final int platformShifts;
  final double hoursMinutes;
  final double platformHoursMinutes;
  final double workValue;
  final double platformWorkValue;
  final double sharePercent;

  const PlatformContribution({
    required this.role,
    required this.shiftsCompleted,
    required this.platformShifts,
    required this.hoursMinutes,
    required this.platformHoursMinutes,
    required this.workValue,
    required this.platformWorkValue,
    required this.sharePercent,
  });

  static const empty = PlatformContribution(
    role: '',
    shiftsCompleted: 0,
    platformShifts: 0,
    hoursMinutes: 0,
    platformHoursMinutes: 0,
    workValue: 0,
    platformWorkValue: 0,
    sharePercent: 0,
  );

  bool get isSeller => role == 'seller';

  factory PlatformContribution.fromJson(Map<String, dynamic> json) {
    return PlatformContribution(
      role: json['role'] as String? ?? '',
      shiftsCompleted: _asInt(json['shifts_completed']),
      platformShifts: _asInt(json['platform_shifts']),
      hoursMinutes: _asDouble(json['hours_minutes']),
      platformHoursMinutes: _asDouble(json['platform_hours_minutes']),
      workValue: _asDouble(json['work_value']),
      platformWorkValue: _asDouble(json['platform_work_value']),
      sharePercent: _asDouble(json['share_percent']),
    );
  }

  static int _asInt(Object? value) => _asDouble(value).round();

  static double _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String get shareLabel {
    final value = sharePercent;
    if (value <= 0) return '0%';
    if (value < 0.01) return '<0.01%';
    if (value >= 10 && value == value.roundToDouble()) {
      return '${value.toInt()}%';
    }
    if (value >= 10) return '${value.toStringAsFixed(1)}%';
    return '${value.toStringAsFixed(2)}%';
  }

  double get shareFraction => (sharePercent / 100).clamp(0.0, 1.0);

  String get hoursLabel => _hoursLabel(hoursMinutes);

  String get platformHoursLabel => _hoursLabel(platformHoursMinutes);

  String get workValueLabel => _moneyLabel(workValue);

  String get platformWorkValueLabel => _moneyLabel(platformWorkValue);

  static String _hoursLabel(double minutes) {
    final hours = minutes / 60.0;
    if (hours == hours.roundToDouble()) return '${hours.toInt()}h';
    return '${hours.toStringAsFixed(1)}h';
  }

  static String _moneyLabel(double value) {
    if (value == value.roundToDouble()) {
      return '$currencySign${value.toInt()}';
    }
    return '$currencySign${value.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
        role,
        shiftsCompleted,
        platformShifts,
        hoursMinutes,
        platformHoursMinutes,
        workValue,
        platformWorkValue,
        sharePercent,
      ];
}
