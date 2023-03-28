part of 'chat_message_bloc.dart';

@immutable
abstract class ChatMessageState {}

class ChatMessageInitial extends ChatMessageState {}

class ChatMessageLoading extends ChatMessageState {}

class ChatMessageLoaded extends ChatMessageState {
  final List<types.Message> messages;

  ChatMessageLoaded(this.messages);
}

class ChatMessageError extends ChatMessageState {
  final String message;

  ChatMessageError(this.message);
}
