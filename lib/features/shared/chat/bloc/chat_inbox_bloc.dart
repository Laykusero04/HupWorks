import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/chat_repository.dart';
import 'chat_inbox_event.dart';
import 'chat_inbox_state.dart';

class ChatInboxBloc extends Bloc<ChatInboxEvent, ChatInboxState> {
  final ChatRepository _chatRepository;
  RealtimeChannel? _messagesChannel;

  ChatInboxBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatInboxInitial()) {
    on<ChatInboxLoadRequested>(_onLoadRequested);
    on<ChatInboxSubscribeRequested>(_onSubscribeRequested);
    on<ChatInboxSendMessage>(_onSendMessage);
    on<ChatInboxMarkReadRequested>(_onMarkReadRequested);
  }

  Future<void> _onLoadRequested(ChatInboxLoadRequested event, Emitter<ChatInboxState> emit) async {
    emit(ChatInboxLoading());
    try {
      final messages = await _chatRepository.getMessages(event.conversationId);
      emit(ChatInboxLoaded(messages: messages));
    } on Failure catch (e) {
      emit(ChatInboxError(e.message));
    } catch (e) {
      emit(ChatInboxError(e.toString()));
    }
  }

  Future<void> _onSubscribeRequested(ChatInboxSubscribeRequested event, Emitter<ChatInboxState> emit) async {
    _messagesChannel = _chatRepository.subscribeToMessages(
      conversationId: event.conversationId,
      onNewMessage: (_) => add(ChatInboxLoadRequested(conversationId: event.conversationId)),
    );
  }

  Future<void> _onSendMessage(ChatInboxSendMessage event, Emitter<ChatInboxState> emit) async {
    emit(ChatInboxSending());
    try {
      await _chatRepository.sendMessage(
        conversationId: event.conversationId,
        content: event.content,
        attachmentUrl: event.attachmentUrl,
      );
      final messages = await _chatRepository.getMessages(event.conversationId);
      emit(ChatInboxLoaded(messages: messages));
    } on Failure catch (e) {
      emit(ChatInboxError(e.message));
    } catch (e) {
      emit(ChatInboxError(e.toString()));
    }
  }

  Future<void> _onMarkReadRequested(ChatInboxMarkReadRequested event, Emitter<ChatInboxState> emit) async {
    try {
      await _chatRepository.markMessagesAsRead(event.conversationId);
    } on Failure catch (e) {
      emit(ChatInboxError(e.message));
    } catch (e) {
      emit(ChatInboxError(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _messagesChannel?.unsubscribe();
    _messagesChannel = null;
    return super.close();
  }
}
