import 'package:equatable/equatable.dart';

import '../../../../data/models/message_model.dart';

abstract class ChatInboxState extends Equatable {
  const ChatInboxState();

  @override
  List<Object?> get props => [];
}

class ChatInboxInitial extends ChatInboxState {}

class ChatInboxLoading extends ChatInboxState {}

class ChatInboxLoaded extends ChatInboxState {
  final List<Message> messages;

  const ChatInboxLoaded({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class ChatInboxSending extends ChatInboxState {}

class ChatInboxError extends ChatInboxState {
  final String message;

  const ChatInboxError(this.message);

  @override
  List<Object?> get props => [message];
}
