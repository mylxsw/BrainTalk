import 'dart:convert';

import 'package:BrainTalk/helper/helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessageDataProvider {
  List<types.Message>? messages;

  Future<List<types.Message>> getRecentMessages() async {
    if (messages == null) {
      await loadMessages();
    }

    return messages!;
  }

  Future<void> sendMessage(types.Message message) async {
    print("sendMessage: $message");
    messages!.insert(0, message);

    await writeFile('chat.json', jsonEncode(messages));
  }

  Future<void> loadMessages() async {
    // final resp = await rootBundle.loadString('assets/messages.json');
    final resp = await readFile('chat.json');
    messages = (jsonDecode(resp) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
