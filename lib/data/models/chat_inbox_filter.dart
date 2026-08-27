/// Inbox filters for separating pre-hire, active work, and past threads.
enum ChatInboxFilter {
  all,
  applications,
  active,
  past,
}

/// Primary relationship tag shown on a conversation card.
enum ChatInboxTag {
  applications,
  active,
  past,
}

/// Relationship flags between the two participants of a conversation.
class ConversationInboxMeta {
  const ConversationInboxMeta({
    this.hasPendingApplication = false,
    this.hasActiveContract = false,
    this.hasPastContract = false,
  });

  final bool hasPendingApplication;
  final bool hasActiveContract;
  final bool hasPastContract;

  static const empty = ConversationInboxMeta();

  ChatInboxTag? get primaryTag {
    if (hasActiveContract) return ChatInboxTag.active;
    if (hasPendingApplication) return ChatInboxTag.applications;
    if (hasPastContract) return ChatInboxTag.past;
    return null;
  }

  bool matches(ChatInboxFilter filter) {
    switch (filter) {
      case ChatInboxFilter.all:
        return true;
      case ChatInboxFilter.applications:
        return hasPendingApplication;
      case ChatInboxFilter.active:
        return hasActiveContract;
      case ChatInboxFilter.past:
        return hasPastContract && !hasActiveContract && !hasPendingApplication;
    }
  }
}
