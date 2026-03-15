import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:flutter_game/app/survivor_app.dart';

Future<void> _pumpMenuTransition(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 320));
}

void main() {
  testWidgets('renders lobby menu', (tester) async {
    await tester.pumpWidget(const SurvivorApp());

    expect(find.text('SURVIVOR PROTOTYPE'), findsOneWidget);
    expect(find.text('1 새게임'), findsOneWidget);
    expect(find.text('2 계속하기'), findsOneWidget);
    expect(find.text('3 상점'), findsOneWidget);
    expect(find.text('4 설정'), findsOneWidget);
    expect(find.text('5 끝내기'), findsOneWidget);
    expect(find.text('보유 골드 0'), findsOneWidget);
  });

  testWidgets('opens store from lobby', (tester) async {
    await tester.pumpWidget(const SurvivorApp());

    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await _pumpMenuTransition(tester);

    expect(find.text('상점'), findsOneWidget);
    expect(find.text('체력 단련'), findsWidgets);
    expect(find.text('기동 훈련'), findsOneWidget);
    expect(find.text('재선택 보급'), findsOneWidget);
    expect(find.text('보유 골드 0'), findsWidgets);
  });

  testWidgets('keyboard space keeps scythe selection through run start', (
    tester,
  ) async {
    await tester.pumpWidget(const SurvivorApp());

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _pumpMenuTransition(tester);
    expect(find.text('캐릭터 선택'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _pumpMenuTransition(tester);
    expect(find.text('무기 선택'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _pumpMenuTransition(tester);

    expect(find.text('맵 선택'), findsOneWidget);
    expect(
      find.text('조선시대 농부 · 던지는 낫 조합으로 출전합니다. 전장의 성격을 고르세요.'),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.textContaining('조선시대 농부 · 던지는 낫 ·'), findsOneWidget);
  });

  testWidgets('keyboard space keeps talisman selection through run start', (
    tester,
  ) async {
    await tester.pumpWidget(const SurvivorApp());

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _pumpMenuTransition(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _pumpMenuTransition(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _pumpMenuTransition(tester);

    expect(find.text('맵 선택'), findsOneWidget);
    expect(find.text('조선시대 농부 · 부적 조합으로 출전합니다. 전장의 성격을 고르세요.'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.textContaining('조선시대 농부 · 부적 ·'), findsOneWidget);
  });
}
