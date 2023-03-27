import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: '1');

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
            return Chat(
              messages: _messages,
              onSendPressed: _onSendPressed,
              user: _user,
              theme: _buildChatTheme(context),
              onAttachmentPressed: _onAttachmentPressed,
              inputOptions: const InputOptions(
                sendButtonVisibilityMode: SendButtonVisibilityMode.always,
              ),
            );
          },
        ),
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

  void _onSendPressed(types.PartialText message) {
    _addMessage(types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: randomId(),
      text: message.text,
    ));
  }

  void _onAttachmentPressed() {
    print('Attachment pressed');
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }
}

String randomId() {
  final random = Random.secure();
  final values = List<int>.generate(16, (index) => random.nextInt(255));
  return base64UrlEncode(values);
}

bool isDarkMode(BuildContext context) {
  return MacosTheme.of(context).brightness.isDark;
}
