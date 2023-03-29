import 'dart:async';
import 'dart:convert';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';

class OpenAIRepository {
  OpenAI? _openAI;

  OpenAIRepository(String openAIToken, {proxy = ''}) {
    _openAI = OpenAI.instance.build(
      token: openAIToken,
      baseOption: HttpSetup(
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        connectTimeout: const Duration(seconds: 10),
        proxy: proxy,
      ),
    );
  }

  Future<void> chatStream(
    List<Map<String, String>> messages,
    void Function(String data) onData, {
    int maxToken = 1000,
    double temperature = 1.0,
    user = 'user',
    model = 'gpt-3.5-turbo',
  }) async {
    final request = ChatCompleteText(
      model: model,
      maxToken: maxToken,
      temperature: temperature,
      messages: messages,
      user: user,
    );

    var completer = Completer<void>();
    _openAI!.onChatCompletionSSE(
        request: request,
        complete: (it) {
          it.map((it) => utf8.decode(it)).listen(
            (data) {
              final raw = data.replaceAll("data: ", '').trim();
              if (raw.isNotEmpty) {
                try {
                  final mJson = json.decode(raw);
                  if (mJson is Map) {
                    String? txt =
                        (mJson['choices'] as List).last['delta']['content'];
                    if (txt != null) {
                      onData(txt);
                    }
                  }
                } catch (e) {
                  if (e is! FormatException) {
                    print("error: $e");
                  }
                }
              }
            },
            onDone: () {
              print('received done');
              completer.complete();
            },
          ).onError((e) {
            completer.completeError(e);
          });
        });

    return completer.future;
  }

  Future<List<ChatReplyMessage>> chat(
    List<Map<String, String>> messages, {
    int maxToken = 1000,
    double temperature = 1.0,
    user = 'user',
    model = 'gpt-3.5-turbo',
  }) async {
    final request = ChatCompleteText(
      model: model,
      maxToken: maxToken,
      temperature: temperature,
      messages: messages,
      user: user,
    );

    final response = await _openAI!.onChatCompletion(request: request);
    if (response != null) {
      return response.choices
          .map((e) => ChatReplyMessage(
              index: e.index,
              content: e.message.content,
              role: e.message.role,
              finishReason: e.finishReason))
          .toList();
    }

    return [];
  }
}

class ChatReplyMessage {
  final int index;
  final String role;
  final String content;
  final String? finishReason;

  ChatReplyMessage({
    required this.index,
    required this.role,
    required this.content,
    this.finishReason,
  });
}
