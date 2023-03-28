import 'chat_message_data.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessageRepository {
  final ChatMessageDataProvider dataProvider;

  ChatMessageRepository(this.dataProvider);

  Future<List<types.Message>> getRecentMessages() async {
    return dataProvider.getRecentMessages();
  }

  Future<void> sendMessage(types.Message message) async {
    return dataProvider.sendMessage(message);
  }
}
