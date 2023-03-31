import 'dart:async';
import 'dart:io';

import 'package:BrainTalk/bloc/chat_message_bloc.dart';
import 'package:BrainTalk/bloc/notify_bloc.dart';
import 'package:BrainTalk/helper/helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as t;
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _user = const t.User(id: '1');

  @override
  void initState() {
    super.initState();
    context.read<ChatMessageBloc>().add(ChatMessageGetRecentEvent());

    // Timer.periodic(const Duration(seconds: 10), (timer) {
    //   context.read<ChatMessageBloc>().add(ChatMessageGetRecentEvent());
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Chat'),
        actions: [
          ToolBarIconButton(
            label: '清空',
            icon: const MacosIcon(
              CupertinoIcons.trash,
              color: Colors.red,
            ),
            showLabel: false,
            tooltipMessage: '清空',
            onPressed: () {
              showMacosAlertDialog(
                context: context,
                builder: (_) => MacosAlertDialog(
                  appIcon: const FlutterLogo(size: 56),
                  title: const Text('确认清空所有消息？'),
                  message: const Text('注意：该操作不可恢复'),
                  primaryButton: PushButton(
                    buttonSize: ButtonSize.large,
                    child: const Text('确定'),
                    onPressed: () {
                      BlocProvider.of<ChatMessageBloc>(context)
                          .add(ChatMessageClearAllEvent());
                      Navigator.of(context).pop();
                    },
                  ),
                  secondaryButton: PushButton(
                      isSecondary: true,
                      buttonSize: ButtonSize.large,
                      child: const Text('取消'),
                      onPressed: () => Navigator.of(context).pop()),
                ),
              );
            },
          ),
          ToolBarIconButton(
            label: '重置上下文',
            icon: const MacosIcon(CupertinoIcons.refresh),
            showLabel: false,
            tooltipMessage: '重置上下文',
            onPressed: () {
              BlocProvider.of<ChatMessageBloc>(context)
                  .add(ChatMessageBreakContextEvent());
            },
          ),
          ToolBarIconButton(
            label: 'Toggle Sidebar',
            icon: const MacosIcon(CupertinoIcons.sidebar_left),
            showLabel: false,
            tooltipMessage: 'Toggle Sidebar',
            onPressed: () {
              MacosWindowScope.of(context).toggleSidebar();
            },
          ),
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return BlocConsumer<ChatMessageBloc, ChatMessageState>(
              buildWhen: (previous, current) => current is ChatMessageLoaded,
              listener: (context, state) {
                if (state is ChatMessageLoaded && state.error != null) {
                  var notifier = context.read<NotifyBloc>();

                  notifier.add(NotifyResetEvent());
                  notifier.add(NotifyFiredEvent('提示', state.error, 'error'));
                }
              },
              builder: (context, state) {
                if (state is ChatMessageLoaded) {
                  return Material(
                    child: Column(children: [
                      BlocBuilder<NotifyBloc, NotifyState>(
                          builder: (context, state) {
                        if (state is NotifyFired) {
                          return Container(
                            color: Colors.red,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Text(
                              '${state.title}: ${state.body}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          );
                        } else {
                          return Container();
                        }
                      }),
                      Expanded(
                          child: Chat(
                        messages: state.messages,
                        onSendPressed: _buildSendPressedHandler(context),
                        user: _user,
                        theme: _buildChatTheme(context),
                        onAttachmentPressed: _buildAttachmentPressedHandler(
                            context.read<ChatMessageBloc>()),
                        inputOptions: const InputOptions(
                          sendButtonVisibilityMode:
                              SendButtonVisibilityMode.always,
                        ),
                        onPreviewDataFetched:
                            _buildPreviewDataFetchedHandler(state),
                        onMessageTap: _buildMessageTapHandler(state),
                        usePreviewData: true,
                        showUserAvatars: true,
                        showUserNames: true,
                        l10n: const ChatL10nZhCN(),
                      )),
                    ]),
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }

  void Function(t.PartialText) _buildSendPressedHandler(BuildContext context) {
    return (t.PartialText message) {
      context.read<ChatMessageBloc>().add(ChatMessageSendEvent(t.TextMessage(
            author: _user,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: randomId(),
            text: message.text,
          )));

      context.read<NotifyBloc>().add(NotifyResetEvent());
    };
  }

  Function() _buildAttachmentPressedHandler(ChatMessageBloc bloc) {
    return () async {
      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        final filePath =
            await copyExternalFileToAppDocs(result.files.single.path!);

        if (['jpg', 'png', 'jpeg', 'gif']
            .contains(result.files.single.extension)) {
          var imageFile = File(filePath);
          var imageData = await imageFile.readAsBytes();
          var image = await decodeImageFromList(imageData);

          bloc.add(
            ChatMessageSendEvent(
              t.ImageMessage(
                author: _user,
                createdAt: DateTime.now().millisecondsSinceEpoch,
                height: image.height.toDouble(),
                id: randomId(),
                name: result.files.single.name,
                size: imageData.length,
                uri: filePath,
                width: image.width.toDouble(),
              ),
            ),
          );
        } else {
          bloc.add(ChatMessageSendEvent(t.FileMessage(
            author: _user,
            id: randomId(),
            createdAt: DateTime.now().millisecondsSinceEpoch,
            name: result.files.single.name,
            size: result.files.single.size,
            uri: result.files.single.path!,
          )));
        }
      }
    };
  }

  void Function(t.TextMessage, t.PreviewData) _buildPreviewDataFetchedHandler(
      ChatMessageLoaded state) {
    return (t.TextMessage message, t.PreviewData previewData) {
      final index =
          state.messages.indexWhere((element) => element.id == message.id);
      setState(() {
        state.messages[index] = (state.messages[index] as t.TextMessage)
            .copyWith(previewData: previewData);
      });
    };
  }

  void Function(BuildContext _, t.Message message) _buildMessageTapHandler(
      ChatMessageLoaded state) {
    return (_, message) async {
      if (message is t.FileMessage) {
        var localPath = message.uri;

        if (message.uri.startsWith('http')) {
          try {
            final index = state.messages
                .indexWhere((element) => element.id == message.id);
            final updatedMessage =
                (state.messages[index] as t.FileMessage).copyWith(
              isLoading: true,
            );

            setState(() {
              state.messages[index] = updatedMessage;
            });

            final client = http.Client();
            final request = await client.get(Uri.parse(message.uri));
            final bytes = request.bodyBytes;
            final documentsDir =
                (await getApplicationDocumentsDirectory()).path;
            localPath = '$documentsDir/${message.name}';

            if (!File(localPath).existsSync()) {
              final file = File(localPath);
              await file.writeAsBytes(bytes);
            }
          } finally {
            final index = state.messages
                .indexWhere((element) => element.id == message.id);
            final updatedMessage =
                (state.messages[index] as t.FileMessage).copyWith(
              isLoading: null,
            );

            setState(() {
              state.messages[index] = updatedMessage;
            });
          }
        }

        await OpenFilex.open(localPath);
      }
    };
  }

  DefaultChatTheme _buildChatTheme(BuildContext context) {
    var defaultTheme = const DefaultChatTheme();
    if (isDarkMode(context)) {
      return DefaultChatTheme(
        backgroundColor: const Color.fromARGB(255, 18, 19, 20),
        inputBackgroundColor: const Color.fromARGB(255, 18, 19, 20),
        messageBorderRadius: 8,
        messageInsetsHorizontal: 10,
        messageInsetsVertical: 7,
        inputBorderRadius: const BorderRadius.all(Radius.zero),
        inputTextStyle: defaultTheme.inputTextStyle.copyWith(fontSize: 14),
        inputTextDecoration: defaultTheme.inputTextDecoration.copyWith(
          contentPadding: const EdgeInsets.all(10),
          focusedBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(color: Color.fromARGB(100, 233, 233, 233)),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        receivedMessageBodyTextStyle:
            defaultTheme.receivedMessageBodyTextStyle.copyWith(
          fontSize: 14,
          color: Colors.white,
        ),
        sentMessageBodyTextStyle:
            defaultTheme.sentMessageBodyTextStyle.copyWith(
          fontSize: 14,
        ),
        primaryColor: const Color.fromARGB(255, 23, 44, 74),
        secondaryColor: const Color.fromARGB(255, 29, 32, 36),
        inputContainerDecoration: const BoxDecoration(
          border:
              Border(top: BorderSide(color: Color.fromARGB(255, 29, 31, 33))),
        ),
      );
    } else {
      return DefaultChatTheme(
        backgroundColor: MacosTheme.of(context).canvasColor,
        inputBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
        messageBorderRadius: 8,
        messageInsetsHorizontal: 10,
        messageInsetsVertical: 7,
        inputBorderRadius: const BorderRadius.all(Radius.zero),
        inputTextStyle: defaultTheme.inputTextStyle.copyWith(fontSize: 14),
        inputTextColor: Colors.black,
        inputTextDecoration: defaultTheme.inputTextDecoration.copyWith(
          contentPadding: const EdgeInsets.all(10),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromARGB(99, 153, 153, 153),
            ),
          ),
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              color: Color.fromARGB(211, 232, 232, 232),
            ),
          ),
        ),
        receivedMessageBodyTextStyle: defaultTheme.receivedMessageBodyTextStyle
            .copyWith(
                fontSize: 14, color: const Color.fromARGB(255, 28, 31, 35)),
        sentMessageBodyTextStyle: defaultTheme.sentMessageBodyTextStyle
            .copyWith(
                fontSize: 14, color: const Color.fromARGB(255, 28, 31, 35)),
        primaryColor: const Color.fromARGB(255, 194, 227, 255),
        inputContainerDecoration: const BoxDecoration(
          border: Border(
              top: BorderSide(color: Color.fromARGB(255, 238, 239, 240))),
        ),
      );
    }
  }
}

bool isDarkMode(BuildContext context) {
  return MacosTheme.of(context).brightness.isDark;
}
