import 'dart:convert';

import 'package:BrainTalk/helper/helper.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessageDataProvider {
  List<types.Message>? _messages;
  bool _dirty = false;

  Future<List<types.Message>> getRecentMessages() async {
    if (_messages == null) {
      await _loadMessages();
    }

    return _messages ?? [];
  }

  Future<types.Message?> getLastMessage() async {
    if (_messages!.isEmpty) {
      return null;
    }

    return _messages?.first;
  }

  Future<void> sendMessage(types.Message message) async {
    _messages!.insert(0, message);
    _dirty = true;
  }

  Future<void> updateMessage(String id, types.Message message) async {
    if (_messages == null) {
      return;
    }

    final index = _messages!.indexWhere((element) => element.id == id);
    if (index > -1) {
      _messages![index] = message;
      _dirty = true;
    }
  }

  Future<void> removeMessage(String id) async {
    final index = _messages!.indexWhere((element) => element.id == id);
    if (index > -1) {
      _messages!.removeAt(index);
      _dirty = true;
    }
  }

  Future<void> clearMessages() async {
    _messages = [];
    _dirty = true;
  }

  Future<void> saveMessages() async {
    if (!_dirty) {
      return;
    }

    await writeFile('chat.json', jsonEncode(_messages));
    _dirty = false;
  }

  Future<void> _loadMessages() async {
    // final resp = await rootBundle.loadString('assets/messages.json');
    final resp = await readFile('chat.json');
    _messages = (jsonDecode(resp) as List)
        .map((e) => types.Message.fromJson(e as Map<String, dynamic>))
        .toList();
    _dirty = false;
  }
}
