import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:freelancer/core/utils/app_logger.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_build.dart';

/// Minimum build the backend accepts for this platform.
class AppUpdateRequirement {
  const AppUpdateRequirement({required this.minBuild, this.updateUrl});

  final int minBuild;
  final String? updateUrl;

  /// Parses the jsonb returned by the `get_min_app_build(platform)` RPC.
  /// Returns null for anything unexpected (the gate then stays open).
  static AppUpdateRequirement? fromRpc(dynamic raw) {
    if (raw is! Map) return null;
    final min = raw['min_build'];
    if (min is! num) return null;
    final url = raw['update_url'];
    return AppUpdateRequirement(
      minBuild: min.toInt(),
      updateUrl: url is String && url.trim().isNotEmpty ? url.trim() : null,
    );
  }

  /// True when [currentBuild] is below the minimum. A minimum of 0 means "no gate".
  bool blocks(int currentBuild) => minBuild > 0 && currentBuild < minBuild;
}

typedef AppUpdateFetcher = Future<AppUpdateRequirement?> Function();

/// Reads the requirement from Supabase. Fails OPEN: any error, timeout or
/// missing function returns null so the app is never blocked by this check.
Future<AppUpdateRequirement?> fetchAppUpdateRequirement() async {
  if (kIsWeb) return null;
  final platform = Platform.isIOS
      ? 'ios'
      : Platform.isAndroid
          ? 'android'
          : null;
  if (platform == null) return null;
  try {
    final raw = await Supabase.instance.client.rpc('get_min_app_build',
        params: {'p_platform': platform}).timeout(const Duration(seconds: 6));
    return AppUpdateRequirement.fromRpc(raw);
  } catch (e, st) {
    AppLogger.error('AppVersionGate.fetch', e, st);
    return null;
  }
}

/// Blocks the app with an "update required" screen when the backend minimum
/// build is above [currentBuild]. Wrap around the router content.
class AppVersionGate extends StatefulWidget {
  const AppVersionGate({
    super.key,
    required this.child,
    this.fetch,
    this.currentBuild = kAppBuildNumber,
  });

  final Widget child;
  final AppUpdateFetcher? fetch;
  final int currentBuild;

  @override
  State<AppVersionGate> createState() => _AppVersionGateState();
}

class _AppVersionGateState extends State<AppVersionGate> {
  AppUpdateRequirement? _blocking;

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  Future<void> _check() async {
    try {
      final req = await (widget.fetch ?? fetchAppUpdateRequirement)();
      if (!mounted || req == null) return;
      if (req.blocks(widget.currentBuild)) setState(() => _blocking = req);
    } catch (e, st) {
      // Fail open: a broken check must never block or crash the app.
      AppLogger.error('AppVersionGate.check', e, st);
    }
  }

  Future<void> _openStore(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final blocking = _blocking;
    if (blocking == null) return widget.child;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        // Keep the app mounted but unreachable behind the blocker.
        ExcludeSemantics(child: IgnorePointer(child: widget.child)),
        Positioned.fill(
          child: PopScope(
            canPop: false,
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.system_update,
                            size: 56, color: scheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          l10n.updateRequiredTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.updateRequiredBody,
                          textAlign: TextAlign.center,
                        ),
                        if (blocking.updateUrl != null) ...[
                          const SizedBox(height: 24),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: FilledButton(
                              onPressed: () => _openStore(blocking.updateUrl!),
                              child: Text(l10n.updateRequiredButton),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
