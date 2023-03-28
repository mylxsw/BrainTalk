import 'package:BrainTalk/chat.dart';
import 'package:BrainTalk/repo/chat_message_data.dart';
import 'package:BrainTalk/repo/chat_message_repo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:macos_ui/macos_ui.dart';

import 'bloc/chat_message_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  App({super.key});

  final chatMessageDataProvider = ChatMessageDataProvider();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => ChatMessageRepository(chatMessageDataProvider),
      child: MacosApp(
        title: 'BrainTalk',
        theme: MacosThemeData.light(),
        darkTheme: MacosThemeData.dark(),
        themeMode: ThemeMode.system,
        home: const MainView(),
        debugShowCheckedModeBanner: false,
      ),
    );
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
              create: (context) =>
                  ChatMessageBloc(context.read<ChatMessageRepository>()),
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
                return const Center(
                  child: Text('Home'),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
