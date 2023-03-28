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
  final _contextAliveTimeMillis = 1000 * 60 * 10;

  ChatMessageBloc(this.chatMessageRepository) : super(ChatMessageInitial()) {
    final openAI = OpenAI.instance.build(
      token: Platform.environment['OPENAI_TOKEN'],
      baseOption: HttpSetup(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        connectTimeout: const Duration(seconds: 10),
      ),
    );

    // 消息发送
    on<ChatMessageSendEvent>((event, emit) async {
      emit(ChatMessageLoading());
      await chatMessageRepository.sendMessage(event.message);

      types.Message? waitMessage = types.SystemMessage(
        id: randomId(),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        text: '机器人正在思考中...',
      );

      try {
        await chatMessageRepository.sendMessage(waitMessage);

        final messages =
            await chatMessageRepository.getRecentMessages(lastAliveTime());
        emit(ChatMessageLoaded(messages));

        if (event.message is types.TextMessage) {
          var contextMessages = messages.reversed
              // 10 分钟内的消息作为一个上下文
              .where((e) => e.createdAt! > lastAliveTime())
              .whereType<types.TextMessage>()
              .map((e) => e.author.id == 'robot'
                  ? {"role": "assistant", "content": e.text}
                  : {"role": "user", "content": e.text})
              .toList();

          contextMessages.add(Map.of({
            "role": "user",
            "content": (event.message as types.TextMessage).text,
          }));

          if (contextMessages.length > 10) {
            contextMessages =
                contextMessages.sublist(contextMessages.length - 10);
          }

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
              await chatMessageRepository.updateMessage(
                waitMessage.id,
                types.TextMessage(
                  id: randomId(),
                  author: const types.User(id: 'robot', firstName: 'Robot'),
                  text: element.message.content,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                ),
              );
            }

            waitMessage = null;
          }
        }
      } finally {
        if (waitMessage != null) {
          await chatMessageRepository.updateMessage(
            waitMessage.id,
            types.SystemMessage(
              id: randomId(),
              createdAt: DateTime.now().millisecondsSinceEpoch,
              text: '❗️机器人貌似出了点问题，请稍后再试',
            ),
          );
        }

        emit(ChatMessageLoaded(
            await chatMessageRepository.getRecentMessages(lastAliveTime())));
      }
    });

    // 页面加载
    on<ChatMessageGetRecentEvent>((event, emit) async {
      emit(ChatMessageLoading());
      emit(ChatMessageLoaded(
          await chatMessageRepository.getRecentMessages(lastAliveTime())));
    });

    // 清空消息
    on<ChatMessageClearAllEvent>((event, emit) async {
      emit(ChatMessageLoading());
      await chatMessageRepository.clearMessages();
      emit(ChatMessageLoaded(
          await chatMessageRepository.getRecentMessages(lastAliveTime())));
    });
  }

  int lastAliveTime() {
    return DateTime.now().millisecondsSinceEpoch - _contextAliveTimeMillis;
  }
}
