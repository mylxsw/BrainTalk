import 'dart:io';

import 'package:BrainTalk/chat.dart';
import 'package:BrainTalk/repo/chat_message_data.dart';
import 'package:BrainTalk/repo/chat_message_repo.dart';
import 'package:BrainTalk/repo/openai_repo.dart';
import 'package:BrainTalk/repo/settings_data.dart';
import 'package:BrainTalk/repo/settings_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

import 'bloc/chat_message_bloc.dart';
import 'helper/constant.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  App({super.key});

  final _chatDataProvider = ChatMessageDataProvider();
  final _settingProvider = SettingDataProvider();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ChatMessageRepository>(
            create: (context) => ChatMessageRepository(
              _chatDataProvider,
            ),
          ),
          RepositoryProvider<OpenAIRepository>(
            create: (context) => OpenAIRepository(
              _settingProvider.getDefault(
                settingOpenAIAPIToken,
                Platform.environment['OPENAI_TOKEN'] ?? '',
              ),
              proxy: _settingProvider.getDefault(settingOpenAIProxy, ''),
            ),
          ),
          RepositoryProvider<SettingRepository>(
            create: (context) => SettingRepository(_settingProvider),
          ),
        ],
        child: MacosApp(
          title: 'BrainTalk',
          theme: MacosThemeData.light(),
          darkTheme: MacosThemeData.dark(),
          themeMode: ThemeMode.system,
          home: const MainView(),
          debugShowCheckedModeBanner: false,
        ));
  }
}

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: const [
        PlatformMenu(
          label: 'BrainTalk',
          menus: [
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.about,
            ),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.quit,
            ),
          ],
        ),
      ],
      child: MacosWindow(
        sidebar: Sidebar(
          minWidth: 200,
          builder: (context, scrollController) => SidebarItems(
            currentIndex: _pageIndex,
            onChanged: (index) {
              setState(() => _pageIndex = index);
            },
            items: const [
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.home),
                label: Text('Home'),
              ),
              SidebarItem(
                leading: MacosIcon(CupertinoIcons.chat_bubble),
                label: Text('Chat'),
              ),
            ],
          ),
        ),
        child: IndexedStack(
          index: _pageIndex,
          children: [
            const HomePage(),
            BlocProvider<ChatMessageBloc>(
              create: (context) => ChatMessageBloc(
                context.read<ChatMessageRepository>(),
                context.read<OpenAIRepository>(),
                context.read<SettingRepository>(),
              ),
              child: const ChatPage(),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return MacosScaffold(
          toolBar: ToolBar(
            title: const Text('Home'),
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
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('API Token:'),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MacosTextField(
                              controller: TextEditingController(
                                text: context
                                    .read<SettingRepository>()
                                    .stringDefault(settingOpenAIAPIToken, ''),
                              ),
                              onChanged: (value) {
                                context
                                    .read<SettingRepository>()
                                    .set(settingOpenAIAPIToken, value);
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Model:'),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MacosTextField(
                              controller: TextEditingController(
                                text: context
                                    .read<SettingRepository>()
                                    .stringDefault(
                                        settingOpenAIModel, "gpt-3.5-turbo"),
                              ),
                              onChanged: (value) {
                                context
                                    .read<SettingRepository>()
                                    .set(settingOpenAIModel, value);
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Temperature:'),
                          const SizedBox(width: 20),
                          Expanded(
                            child: MacosTextField(
                              controller: TextEditingController(
                                text: context
                                    .read<SettingRepository>()
                                    .stringDefault(
                                        settingOpenAITemperature, '1.0'),
                              ),
                              onChanged: (value) {
                                context
                                    .read<SettingRepository>()
                                    .set(settingOpenAITemperature, value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
