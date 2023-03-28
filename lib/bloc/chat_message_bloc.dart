import 'package:BrainTalk/helper/helper.dart';
import 'package:BrainTalk/repo/chat_message_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

part 'chat_event.dart';
part 'chat_state.dart';

class ChatMessageBloc extends Bloc<ChatMessageEvent, ChatMessageState> {
  final ChatMessageRepository chatMessageRepository;

  ChatMessageBloc(this.chatMessageRepository) : super(ChatMessageInitial()) {
    on<ChatMessageSendEvent>((event, emit) async {
      emit(ChatMessageLoading());
      await chatMessageRepository.sendMessage(event.message);

      emit(ChatMessageLoaded(await chatMessageRepository.getRecentMessages()));

      await Future.delayed(const Duration(seconds: 3), () async {
        print('delay task executed');
        await chatMessageRepository.sendMessage(types.TextMessage(
          id: randomId(),
          author: const types.User(id: 'robot', firstName: 'Robot'),
          text: 'Received.',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ));

        emit(
            ChatMessageLoaded(await chatMessageRepository.getRecentMessages()));
      });
    });

    on<ChatMessageGetRecentEvent>((event, emit) async {
      emit(ChatMessageLoading());
      emit(ChatMessageLoaded(await chatMessageRepository.getRecentMessages()));
    });
  }
}
