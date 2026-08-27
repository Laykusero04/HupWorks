/// Order metadata shown at the top of a contract-aware chat thread.
class ChatOrderContext {
  const ChatOrderContext({
    required this.orderId,
    required this.title,
    required this.statusLabel,
    required this.isClientViewer,
    this.deadlineLabel,
  });

  final String orderId;
  final String title;
  final String statusLabel;
  final String? deadlineLabel;

  /// Whether the viewer is the client (opens [ClientOrderDetails] on tap).
  final bool isClientViewer;
}
