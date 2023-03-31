// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:BrainTalk/repo/openai_repo2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

import 'package:BrainTalk/main.dart';

void main() {
  testWidgets(
    'Test',
    (WidgetTester tester) async {
      var repo = OpenAIRepository2(Platform.environment['OPENAI_TOKEN']!);
      var models = await repo.supportModels();

      models.forEach((element) {
        print(element);
      });

      expect(true, models.isNotEmpty);
    },
  );
}
