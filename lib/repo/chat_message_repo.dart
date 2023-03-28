import 'package:BrainTalk/helper/helper.dart';

import 'chat_message_data.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessageRepository {
  final ChatMessageDataProvider dataProvider;

  ChatMessageRepository(this.dataProvider);

  Future<List<types.Message>> getRecentMessages(int lastAliveTime) async {
    final recentMessages = (await dataProvider.getRecentMessages()).toList();
    var lastAliveIndex = recentMessages
        .indexWhere((element) => element.createdAt! < lastAliveTime);
    if (lastAliveIndex > -1 &&
        recentMessages[lastAliveIndex].type != types.MessageType.system) {
      recentMessages.insert(
        lastAliveIndex,
        types.SystemMessage(
          id: randomId(),
          createdAt: DateTime.now().millisecondsSinceEpoch,
          text: '~ 以上消息已不在当前上下文 ~',
        ),
      );
    }
    return recentMessages;
  }

  Future<void> sendMessage(types.Message message) async {
    return await dataProvider.sendMessage(message);
  }

  Future<void> updateMessage(String id, types.Message message) async {
    return await dataProvider.updateMessage(id, message);
  }

  Future<void> clearMessages() async {
    await dataProvider.clearMessages();
  }
}
