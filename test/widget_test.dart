import 'package:flag_genuis/widgets/answer_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Answer button renders label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerButton(label: 'Egypt', onTap: () {}),
        ),
      ),
    );

    expect(find.text('Egypt'), findsOneWidget);
  });
}
