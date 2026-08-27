/// A related job application or active contract shared by a chat pair.
enum ChatThreadContextKind { order, jobOffer }

class ChatThreadContextItem {
  const ChatThreadContextItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.statusLabel,
    required this.statusKey,
    this.deadlineLabel,
    this.jobPostId,
    this.preferredContactLabel,
    this.isWithinPreferredWindow = false,
  });

  final ChatThreadContextKind kind;
  final String id;
  final String title;
  final String statusLabel;
  final String statusKey;
  final String? deadlineLabel;

  /// Present for [ChatThreadContextKind.jobOffer] (and sometimes orders).
  final String? jobPostId;

  /// Soft preferred contact windows from shift ±1h (hired orders only).
  final String? preferredContactLabel;
  final bool isWithinPreferredWindow;

  bool get isOrder => kind == ChatThreadContextKind.order;
}
