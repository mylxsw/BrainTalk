import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:BrainTalk/bloc/chat_message_bloc.dart';
import 'package:BrainTalk/helper/helper.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _user = const types.User(id: '1');

  @override
  void initState() {
    super.initState();
    context.read<ChatMessageBloc>().add(ChatMessageGetRecentEvent());
  }

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
        title: const Text('Chat'),
        actions: [
          ToolBarIconButton(
            label: 'Toggle Sidebar',
            icon: const MacosIcon(CupertinoIcons.sidebar_left),
            showLabel: false,
            tooltipMessage: 'Toggle Sidebar',
            onPressed: () {
              MacosWindowScope.of(context).toggleSidebar();
            },
          )
        ],
      ),
      children: [
        ContentArea(
          builder: (context, scrollController) {
            return BlocBuilder<ChatMessageBloc, ChatMessageState>(
              buildWhen: (previous, current) => current is ChatMessageLoaded,
              builder: (context, state) {
                if (state is ChatMessageLoaded) {
                  return Chat(
                    messages: state.messages,
                    onSendPressed: _onSendPressed(context),
                    user: _user,
                    theme: _buildChatTheme(context),
                    onAttachmentPressed:
                        _onAttachmentPressed(context.read<ChatMessageBloc>()),
                    inputOptions: const InputOptions(
                      sendButtonVisibilityMode: SendButtonVisibilityMode.always,
                    ),
                    onPreviewDataFetched: _handlePreviewDataFetched(state),
                    onMessageTap: _handleMessageTap(state),
                    usePreviewData: true,
                    showUserAvatars: true,
                    showUserNames: true,
                  );
                } else {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            );
          },
        )
      ],
    );
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
            defaultTheme.receivedMessageBodyTextStyle.copyWith(fontSize: 14),
        sentMessageBodyTextStyle:
            defaultTheme.sentMessageBodyTextStyle.copyWith(
          fontSize: 14,
        ),
        primaryColor: const Color.fromARGB(255, 23, 44, 74),
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

  void Function(types.PartialText) _onSendPressed(BuildContext context) {
    return (types.PartialText message) {
      context
          .read<ChatMessageBloc>()
          .add(ChatMessageSendEvent(types.TextMessage(
            author: _user,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            id: randomId(),
            text: message.text,
          )));
    };
  }

  Function() _onAttachmentPressed(ChatMessageBloc bloc) {
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
              types.ImageMessage(
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
          bloc.add(ChatMessageSendEvent(types.FileMessage(
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

  void Function(types.TextMessage message, types.PreviewData previewData)
      _handlePreviewDataFetched(ChatMessageLoaded state) {
    return (types.TextMessage message, types.PreviewData previewData) {
      final index =
          state.messages.indexWhere((element) => element.id == message.id);
      setState(() {
        state.messages[index] = (state.messages[index] as types.TextMessage)
            .copyWith(previewData: previewData);
      });
    };
  }

  void Function(BuildContext _, types.Message message) _handleMessageTap(
      ChatMessageLoaded state) {
    return (_, message) async {
      if (message is types.FileMessage) {
        var localPath = message.uri;

        if (message.uri.startsWith('http')) {
          try {
            final index = state.messages
                .indexWhere((element) => element.id == message.id);
            final updatedMessage =
                (state.messages[index] as types.FileMessage).copyWith(
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
                (state.messages[index] as types.FileMessage).copyWith(
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
}

bool isDarkMode(BuildContext context) {
  return MacosTheme.of(context).brightness.isDark;
}
