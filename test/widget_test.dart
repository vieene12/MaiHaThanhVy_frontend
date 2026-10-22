import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maihathanhvy_frontend/main.dart';
import 'package:maihathanhvy_frontend/core/utils/storage_service.dart';

void main() {
  testWidgets('App basic initialization smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();

    await tester.pumpWidget(const StudentAttendanceApp());
    // Advance past the 1800ms splash screen timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(StudentAttendanceApp), findsOneWidget);
  });
}
