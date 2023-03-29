part of 'chat_message_bloc.dart';

@immutable
abstract class ChatMessageEvent {}

class ChatMessageReceivedEvent extends ChatMessageEvent {
  final types.Message message;

  ChatMessageReceivedEvent(this.message);
}

class ChatMessageSendEvent extends ChatMessageEvent {
  final types.Message message;

  ChatMessageSendEvent(this.message);
}

class ChatMessageGetRecentEvent extends ChatMessageEvent {}

class ChatMessageClearAllEvent extends ChatMessageEvent {}

class ChatMessageBreakContextEvent extends ChatMessageEvent {}
