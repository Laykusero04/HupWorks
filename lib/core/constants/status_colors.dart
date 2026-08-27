import 'package:flutter/material.dart';

/// Semantic status colors used across orders, applications, and job posts.
/// Green = accepted / active / completed · Orange = pending · Red = cancelled / rejected
abstract final class StatusColors {
  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);
  static const warning = Color(0xFFF97316);
  static const warningBg = Color(0xFFFFEDD5);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);
  static const neutral = Color(0xFF636E72);
  static const neutralBg = Color(0xFFF4F4F5);

  /// Orders & contracts
  static (Color fg, Color bg) order(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'active':
      case 'completed':
        return (success, successBg);
      case 'pending':
      case 'delivered':
      case 'cancellation_requested':
        return (warning, warningBg);
      case 'cancelled':
        return (danger, dangerBg);
      default:
        return (neutral, neutralBg);
    }
  }

  /// Job applications / offers
  static (Color fg, Color bg) application(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'accepted':
        return (success, successBg);
      case 'rejected':
        return (danger, dangerBg);
      case 'pending':
      default:
        return (warning, warningBg);
    }
  }

  /// Job post listing status
  static (Color fg, Color bg) jobPost(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'open':
        return (success, successBg);
      case 'closed':
        return (neutral, neutralBg);
      default:
        return (neutral, neutralBg);
    }
  }
}
