import 'dart:async';

import 'package:flutter/services.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// QR punches must fall inside this radius of `job_posts` latitude/longitude.
/// Keep in sync with migration 0048.
const double attendanceGeofenceMeters = 200;

enum AttendanceGpsBlock {
  servicesOff,
  denied,
  deniedForever,
  unavailable,
}

class AttendanceGpsException implements Exception {
  const AttendanceGpsException(this.block);
  final AttendanceGpsBlock block;
}

/// Current device position for an attendance punch.
Future<({double latitude, double longitude})> readAttendancePosition() async {
  final serviceOn = await Geolocator.isLocationServiceEnabled();
  if (!serviceOn) {
    throw const AttendanceGpsException(AttendanceGpsBlock.servicesOff);
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw const AttendanceGpsException(AttendanceGpsBlock.denied);
  }
  if (permission == LocationPermission.deniedForever) {
    throw const AttendanceGpsException(AttendanceGpsBlock.deniedForever);
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (latitude: pos.latitude, longitude: pos.longitude);
  } on TimeoutException {
    throw const AttendanceGpsException(AttendanceGpsBlock.unavailable);
  } on MissingPluginException {
    throw const AttendanceGpsException(AttendanceGpsBlock.unavailable);
  } catch (_) {
    throw const AttendanceGpsException(AttendanceGpsBlock.unavailable);
  }
}

String attendanceGpsMessage(AppLocalizations l10n, AttendanceGpsBlock block) {
  switch (block) {
    case AttendanceGpsBlock.servicesOff:
      return l10n.attendanceLocationServicesOff;
    case AttendanceGpsBlock.denied:
      return l10n.attendanceLocationDenied;
    case AttendanceGpsBlock.deniedForever:
      return l10n.attendanceLocationDeniedForever;
    case AttendanceGpsBlock.unavailable:
      return l10n.attendanceLocationRequired;
  }
}

/// Maps geofence errors raised by the attendance RPCs.
String attendanceRpcMessage(AppLocalizations l10n, Object error) {
  final raw = error is PostgrestException ? error.message : '$error';
  if (raw.contains('ATTENDANCE_TOO_FAR')) return l10n.attendanceTooFarFromSite;
  if (raw.contains('ATTENDANCE_NO_SITE_PIN')) return l10n.attendanceNoSitePin;
  if (raw.contains('ATTENDANCE_LOCATION_REQUIRED')) {
    return l10n.attendanceLocationRequired;
  }
  return l10n.errorWithDetail(raw);
}
