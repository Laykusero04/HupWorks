import 'package:equatable/equatable.dart';

abstract class ChatListEvent extends Equatable {
  const ChatListEvent();

  @override
  List<Object?> get props => [];
}

class ChatListLoadRequested extends ChatListEvent {}

class ChatListSubscribeRequested extends ChatListEvent {}

class ChatListUnsubscribeRequested extends ChatListEvent {}
