import 'dart:io';

import 'package:BrainTalk/helper/helper.dart';
import 'package:BrainTalk/repo/chat_message_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:meta/meta.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

part 'chat_event.dart';
part 'chat_state.dart';

class ChatMessageBloc extends Bloc<ChatMessageEvent, ChatMessageState> {
  final ChatMessageRepository chatMessageRepository;

  ChatMessageBloc(this.chatMessageRepository) : super(ChatMessageInitial()) {
    final openAI = OpenAI.instance.build(
      token: Platform.environment['OPENAI_TOKEN'],
      baseOption: HttpSetup(
          receiveTimeout: const Duration(seconds: 300),
          connectTimeout: const Duration(seconds: 10)),
      isLog: true,
    );

    // 消息发送
    on<ChatMessageSendEvent>((event, emit) async {
      emit(ChatMessageLoading());
      await chatMessageRepository.sendMessage(event.message);

      final messages = await chatMessageRepository.getRecentMessages();
      emit(ChatMessageLoaded(messages));

      if (event.message is types.TextMessage) {
        final contextMessages = messages
            // 10 分钟内的消息作为一个上下文
            .where((e) =>
                e.createdAt! >
                DateTime.now().millisecondsSinceEpoch - 1000 * 60 * 10)
            .whereType<types.TextMessage>()
            .map((e) => e.author.id == 'robot'
                ? {"role": "assistant", "content": e.text}
                : {"role": "user", "content": e.text})
            .toList();

        contextMessages.add(Map.of({
          "role": "user",
          "content": (event.message as types.TextMessage).text,
        }));

        final request = ChatCompleteText(
          model: kChatGptTurboModel,
          maxToken: 1000,
          temperature: 0.9,
          messages: contextMessages,
          user: "user",
        );

        final response = await openAI.onChatCompletion(request: request);
        if (response != null) {
          for (var element in response.choices) {
            await chatMessageRepository.sendMessage(types.TextMessage(
              id: randomId(),
              author: const types.User(id: 'robot', firstName: 'Robot'),
              text: element.message.content,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ));

            emit(ChatMessageLoaded(
                await chatMessageRepository.getRecentMessages()));
          }
        }
      }
    });

    // 页面加载
    on<ChatMessageGetRecentEvent>((event, emit) async {
      emit(ChatMessageLoading());
      emit(ChatMessageLoaded(await chatMessageRepository.getRecentMessages()));
    });
  }
}
