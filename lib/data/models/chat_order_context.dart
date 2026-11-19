/// Order metadata shown at the top of a contract-aware chat thread.
class ChatOrderContext {
  const ChatOrderContext({
    required this.orderId,
    required this.title,
    required this.statusLabel,
    required this.isClientViewer,
    this.statusKey,
    this.deadlineLabel,
    this.preferredContactLabel,
    this.isWithinPreferredWindow = false,
  });

  final String orderId;
  final String title;
  final String statusLabel;

  /// Raw order status. When set, the banner derives its label from this at
  /// build time so it follows a language switch ([statusLabel] is a snapshot).
  final String? statusKey;
  final String? deadlineLabel;

  /// Soft ±1h windows around shift start/end (guidance only).
  final String? preferredContactLabel;
  final bool isWithinPreferredWindow;

  /// Whether the viewer is the client (opens [ClientOrderDetails] on tap).
  final bool isClientViewer;
}
