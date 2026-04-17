import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/chat_repository.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository _chatRepository;
  RealtimeChannel? _conversationsChannel;

  ChatListBloc({required ChatRepository chatRepository})
      : _chatRepository = chatRepository,
        super(ChatListInitial()) {
    on<ChatListLoadRequested>(_onLoadRequested);
    on<ChatListSubscribeRequested>(_onSubscribeRequested);
    on<ChatListUnsubscribeRequested>(_onUnsubscribeRequested);
  }

  Future<void> _onLoadRequested(ChatListLoadRequested event, Emitter<ChatListState> emit) async {
    emit(ChatListLoading());
    try {
      final conversations = await _chatRepository.getConversations();
      emit(ChatListLoaded(conversations: conversations));
    } on Failure catch (e) {
      emit(ChatListError(e.message));
    } catch (e) {
      emit(ChatListError(e.toString()));
    }
  }

  Future<void> _onSubscribeRequested(ChatListSubscribeRequested event, Emitter<ChatListState> emit) async {
    _conversationsChannel = _chatRepository.subscribeToConversations(
      onUpdate: () => add(ChatListLoadRequested()),
    );
  }

  Future<void> _onUnsubscribeRequested(ChatListUnsubscribeRequested event, Emitter<ChatListState> emit) async {
    await _conversationsChannel?.unsubscribe();
    _conversationsChannel = null;
  }

  @override
  Future<void> close() async {
    await _conversationsChannel?.unsubscribe();
    _conversationsChannel = null;
    return super.close();
  }
}
