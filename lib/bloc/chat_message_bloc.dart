import 'package:BrainTalk/helper/constant.dart';
import 'package:BrainTalk/helper/helper.dart';
import 'package:BrainTalk/repo/chat_message_repo.dart';
import 'package:BrainTalk/repo/openai_repo.dart';
import 'package:BrainTalk/repo/openai_repo2.dart';
import 'package:BrainTalk/repo/settings_repo.dart';
import 'package:bloc/bloc.dart';
import 'package:dart_openai/openai.dart';
import 'package:meta/meta.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

part 'chat_event.dart';
part 'chat_state.dart';

class ChatMessageBloc extends Bloc<ChatMessageEvent, ChatMessageState> {
  final ChatMessageRepository _chatMsgRepo;
  final OpenAIRepository2 _openAIRepo;
  final SettingRepository _settingRepo;

  final _contextAliveTimeMillis = 1000 * 60 * 30;

  ChatMessageBloc(
    this._chatMsgRepo,
    this._openAIRepo,
    this._settingRepo,
  ) : super(ChatMessageInitial()) {
    on<ChatMessageSendEvent>(_messageSendEventHandler);
    on<ChatMessageGetRecentEvent>(_getRecentEventHandler);
    on<ChatMessageClearAllEvent>(_clearAllEventHandler);
    on<ChatMessageBreakContextEvent>(_breakContextEventHandler);
  }

  /// 计算当前上下文允许的最大活跃时间
  int lastAliveTime() {
    return DateTime.now().millisecondsSinceEpoch - _contextAliveTimeMillis;
  }

  /// 设置上下文清理标识
  Future<void> _breakContextEventHandler(event, emit) async {
    final lastMessage = await _chatMsgRepo.getLastMessage();

    if (lastMessage != null &&
        lastMessage.metadata != null &&
        lastMessage.metadata![contextBreakKey] == true) {
      return;
    }

    await _chatMsgRepo.sendMessage(types.SystemMessage(
      id: randomId(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      text: '~ 上下文已清空 ~',
      metadata: Map.of({contextBreakKey: true}),
    ));

    emit(ChatMessageLoaded(
        await _chatMsgRepo.getRecentMessages(lastAliveTime())));
  }

  /// 清空消息事件处理
  Future<void> _clearAllEventHandler(event, emit) async {
    emit(ChatMessageLoading());
    await _chatMsgRepo.clearMessages();
    emit(ChatMessageLoaded(
        await _chatMsgRepo.getRecentMessages(lastAliveTime())));
  }

  /// 页面加载事件处理
  Future<void> _getRecentEventHandler(event, emit) async {
    emit(ChatMessageLoading());
    emit(ChatMessageLoaded(
        await _chatMsgRepo.getRecentMessages(lastAliveTime())));
  }

  /// 消息发送事件处理
  Future<void> _messageSendEventHandler(event, emit) async {
    emit(ChatMessageLoading());

    // 发送消息
    await _chatMsgRepo.sendMessage(event.message);

    // 请求机器人应答
    types.Message? waitMessage = types.SystemMessage(
      id: randomId(),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      text: '机器人正在思考中...',
    );

    try {
      // 写入机器人思考中的系统消息
      await _chatMsgRepo.sendMessage(waitMessage);

      final messages = await _chatMsgRepo.getRecentMessages(lastAliveTime());
      emit(ChatMessageLoaded(messages));

      if (event.message is types.TextMessage) {
        // // 请求机器人应答
        // final replies = await _openAIRepository
        //     .chat(_buildRobotRequestContext(messages, event));
        // if (replies.isNotEmpty) {
        //   for (var element in replies) {
        //     await _chatMessageRepository.updateMessage(
        //       waitMessage.id,
        //       types.TextMessage(
        //         id: randomId(),
        //         author: const types.User(id: 'robot', firstName: 'Robot'),
        //         text: element.content,
        //         createdAt: DateTime.now().millisecondsSinceEpoch,
        //       ),
        //     );
        //   }

        //   waitMessage = null;
        // }

        types.TextMessage msg = types.TextMessage(
          id: waitMessage.id,
          author: const types.User(id: 'robot', firstName: 'Robot'),
          text: '',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        await _openAIRepo.chatStream(
          _buildRobotRequestContext(messages, event),
          (data) async {
            msg = types.TextMessage(
              id: msg.id,
              author: msg.author,
              text: msg.text + data,
              createdAt: msg.createdAt,
            );

            await _chatMsgRepo.updateMessage(msg.id, msg);
            emit(ChatMessageLoaded(
                await _chatMsgRepo.getRecentMessages(lastAliveTime())));
          },
          maxToken: _settingRepo.intDefault(settingOpenAIMaxToken, 1000),
          temperature:
              _settingRepo.doubleDefault(settingOpenAITemperature, 1.0),
          model:
              _settingRepo.stringDefault(settingOpenAIModel, "gpt-3.5-turbo"),
        );

        waitMessage = null;
      }

      emit(ChatMessageLoaded(
          await _chatMsgRepo.getRecentMessages(lastAliveTime())));
    } catch (e) {
      if (waitMessage != null) {
        await _chatMsgRepo.updateMessage(
          waitMessage.id,
          types.SystemMessage(
            id: randomId(),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            text: '❗️机器人貌似出了点问题，请稍后再试',
          ),
        );
      }

      emit(ChatMessageLoaded(
        await _chatMsgRepo.getRecentMessages(lastAliveTime()),
        error: _resolveErrorMessage(e),
      ));
    }
  }

  String _resolveErrorMessage(dynamic e) {
    if (e is RequestFailedException) {
      return "${e.statusCode}: ${e.message}";
    }

    return e.toString();
  }

  List<OpenAIChatCompletionChoiceMessageModel> _buildRobotRequestContext(
    List<types.Message> messages,
    event,
  ) {
    // 10 分钟内的消息作为一个上下文
    var recentMessages =
        messages.where((e) => e.createdAt! > lastAliveTime()).toList();
    int contextBreakIndex = recentMessages.indexWhere((element) =>
        element.type == types.MessageType.system &&
        element.metadata != null &&
        element.metadata!.containsKey(contextBreakKey));

    if (contextBreakIndex > -1) {
      recentMessages = recentMessages.sublist(0, contextBreakIndex);
    }

    var contextMessages = recentMessages.reversed
        .whereType<types.TextMessage>()
        .map((e) => e.author.id == 'robot'
            ? OpenAIChatCompletionChoiceMessageModel(
                role: OpenAIChatMessageRole.assistant, content: e.text)
            : OpenAIChatCompletionChoiceMessageModel(
                role: OpenAIChatMessageRole.user, content: e.text))
        .toList();

    contextMessages.add(OpenAIChatCompletionChoiceMessageModel(
      role: OpenAIChatMessageRole.user,
      content: (event.message as types.TextMessage).text,
    ));

    if (contextMessages.length > 10) {
      contextMessages = contextMessages.sublist(contextMessages.length - 10);
    }

    return contextMessages;
  }
}
