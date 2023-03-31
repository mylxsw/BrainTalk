part of 'chat_message_bloc.dart';

@immutable
abstract class ChatMessageState {}

class ChatMessageInitial extends ChatMessageState {}

class ChatMessageLoading extends ChatMessageState {}

class ChatMessageLoaded extends ChatMessageState {
  final List<types.Message> _messages;
  final String? _error;

  ChatMessageLoaded(this._messages, {String? error}) : _error = error;

  get messages => _messages;
  get error => _error;
}

class ChatMessageError extends ChatMessageState {
  final String message;

  ChatMessageError(this.message);
}
