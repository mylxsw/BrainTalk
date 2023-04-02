import 'dart:async';

import 'package:dart_openai/openai.dart';

class OpenAIRepository {
  OpenAIRepository(String token) {
    OpenAI.apiKey = token;
    OpenAI.baseUrl = 'https://api.openai.com';
    OpenAI.showLogs = false;
  }

  Future<List<Model>> supportModels() async {
    var models = await OpenAI.instance.model.list();
    return models
        .where((e) => e.ownedBy == 'openai')
        .map((e) => Model(e.id, e.ownedBy))
        .toList();
  }

  Future<void> chatStream(
    List<OpenAIChatCompletionChoiceMessageModel> messages,
    void Function(String data) onData, {
    int maxToken = 1000,
    double temperature = 1.0,
    user = 'user',
    model = 'gpt-3.5-turbo',
  }) async {
    var completer = Completer<void>();

    try {
      var chatStream = OpenAI.instance.chat.createStream(
        model: model,
        messages: messages,
        maxTokens: maxToken,
        temperature: temperature,
        user: user,
      );

      chatStream.listen(
        (event) {
          for (var element in event.choices) {
            if (element.delta.content != null) {
              onData(element.delta.content!);
            }
          }
        },
        onDone: () => completer.complete(),
        onError: (e) => completer.completeError(e),
        cancelOnError: true,
      ).onError((e) {
        completer.completeError(e);
      });
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
  }
}

class Model {
  final String id;
  final String ownedBy;

  Model(this.id, this.ownedBy);
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
