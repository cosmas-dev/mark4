import 'package:flutter_test/flutter_test.dart';
import 'package:mark4/main.dart'; // ← 실제 앱 실행 파일 import
import 'package:flutter/material.dart';

void main() {
  testWidgets("RunTest Flow - Popup appears and inputs work", (tester) async {
    // 앱 실행
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // ========== 1. RUN TEST 화면 이동 ==========
    final runTestButton = find.text("RUN TEST");
    expect(runTestButton, findsOneWidget);

    await tester.tap(runTestButton);
    await tester.pumpAndSettle();

    // ========== 2. Start 버튼 → 팝업 등장 ==========
    final startButton = find.text("Start");
    expect(startButton, findsOneWidget);

    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // 팝업 타이틀 확인
    expect(find.text("Channel Information"), findsOneWidget);

    // ========== 3. User ID 입력 ==========
    final userIdField1 = find.byType(TextField).at(0);
    expect(userIdField1, findsOneWidget);

    await tester.enterText(userIdField1, "kim");
    await tester.pump();

    final userIdField2 = find.byType(TextField).at(1);
    await tester.enterText(userIdField2, "lee");

    final userIdField3 = find.byType(TextField).at(2);
    await tester.enterText(userIdField3, "choi");

    await tester.pumpAndSettle();

    // ========== 4. Age 입력 ==========
    final ageField1 = find.byType(TextField).at(3);
    await tester.enterText(ageField1, "25");

    final ageField2 = find.byType(TextField).at(4);
    await tester.enterText(ageField2, "33");

    final ageField3 = find.byType(TextField).at(5);
    await tester.enterText(ageField3, "41");

    await tester.pumpAndSettle();

    // ========== 5. Gender 선택 ==========
    final femaleRadio = find.byType(Radio).at(1); // CH-1 Female
    await tester.tap(femaleRadio);

    await tester.pumpAndSettle();

    // ========== 6. Next 버튼 눌러보기 ==========
    final nextBtn = find.text("Next");
    expect(nextBtn, findsOneWidget);

    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // next 눌러도 팝업 닫히진 않도록 되어 있으면 그대로 유지됨.
    // 닫히는 걸 기대한다면 아래 주석을 반대로 바꿔야 함:
    // expect(find.text("Channel Information"), findsNothing);

    expect(find.text("Channel Information"), findsOneWidget);
  });
}
