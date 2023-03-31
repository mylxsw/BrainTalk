import 'dart:async';
import 'dart:math';

import 'package:BrainTalk/repo/openai_repo.dart';
import 'package:dart_openai/openai.dart';

class OpenAIRepository2 {
  OpenAIRepository2(String token) {
    OpenAI.apiKey = token;
    OpenAI.baseUrl = 'https://api.openai.com';
    OpenAI.showLogs = false;
  }

  Future<List<Model>> supportModels() async {
    var models = await OpenAI.instance.model.list();
    return models.map((e) => Model(e.id, e.ownedBy)).toList();
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
            print(element);
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
