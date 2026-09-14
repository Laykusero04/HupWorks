import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';

import '../constants/text_styles.dart';

/// App-wide connectivity status for seller and employer shells.
class ConnectivityController extends ChangeNotifier {
  ConnectivityController({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = true;
  bool _started = false;

  bool get isOnline => _online;
  bool get isOffline => !_online;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final initial = await _connectivity.checkConnectivity();
      _apply(initial);
    } catch (_) {
      // Assume online if the platform check fails.
      _online = true;
    }
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    final next = results.any((r) => r != ConnectivityResult.none);
    if (next == _online) return;
    _online = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

class ConnectivityScope extends InheritedNotifier<ConnectivityController> {
  const ConnectivityScope({
    super.key,
    required ConnectivityController controller,
    required super.child,
  }) : super(notifier: controller);

  static ConnectivityController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ConnectivityScope>();
    assert(scope != null, 'ConnectivityScope not found');
    return scope!.notifier!;
  }

  static ConnectivityController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ConnectivityScope>()
        ?.notifier;
  }
}

/// Compact offline strip — status-bar safe, soft warning styling.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final l10n = context.l10n;

    return Material(
      color: const Color(0xFFFFF4E5),
      elevation: 0,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFFFE0B2)),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, top + 8, 14, 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0B2),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFB86E00),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.youAreOffline,
                  style: kTextStyle.copyWith(
                    color: const Color(0xFF8A5A00),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] with a sticky offline strip above the navigator content.
class OfflineAware extends StatelessWidget {
  const OfflineAware({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = ConnectivityScope.maybeOf(context);
    if (controller == null) return child;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final offline = controller.isOffline;
        return Column(
          children: [
            if (offline) const OfflineBanner(),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: offline,
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }
}
