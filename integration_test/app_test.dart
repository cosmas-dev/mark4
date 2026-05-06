import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mark4/main.dart';
import 'package:flutter/material.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
  });
  testWidgets("Test Flow", (tester) async {
    await tester.pumpWidget(const MyApp(ip: "192.168.0.105"));
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

    // ========== 3. 이름 입력 ==========
    final userIdField1 = find.byType(TextField).at(0);
    expect(userIdField1, findsOneWidget);

    await tester.enterText(userIdField1, "kim");
    await tester.pump();

    final userIdField2 = find.byType(TextField).at(1);
    await tester.enterText(userIdField2, "lee");

    final userIdField3 = find.byType(TextField).at(2);
    await tester.enterText(userIdField3, "park");

    await tester.pumpAndSettle();

    // ========== 4. 나이 입력 ==========
    final ageField1 = find.byType(TextField).at(3);
    await tester.enterText(ageField1, "25");

    final ageField2 = find.byType(TextField).at(4);
    await tester.enterText(ageField2, "33");

    final ageField3 = find.byType(TextField).at(5);
    await tester.enterText(ageField3, "41");

    await tester.pumpAndSettle();

    // ========== 5. 성별 선택 ==========
    // await tester.tap(find.byKey(const Key("gender_0_male"))); // CH-1
    // await tester.pumpAndSettle();

    // await tester.tap(find.byKey(const Key("gender_1_male"))); // CH-2
    // await tester.pumpAndSettle();

    // await tester.tap(find.byKey(const Key("gender_2_male"))); // CH-3
    // await tester.pumpAndSettle();

    // ========== 6. Next 버튼 눌러보기 ==========
    final nextBtn = find.text("Next");
    expect(nextBtn, findsOneWidget);

    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // next 눌러도 팝업 닫히진 않도록 되어 있으면 그대로 유지됨.
    // 닫히는 걸 기대한다면 아래 주석을 반대로 바꿔야 함:
    // expect(find.text("Channel Information"), findsNothing);

    // expect(find.text("Channel Information"), findsOneWidget);

    // ========== 7. Run 버튼 눌러보기 ==========
    final runBtn = find.text("Run");
    expect(runBtn, findsOneWidget);
  });
}
