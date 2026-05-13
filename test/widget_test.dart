import 'package:ass_ops_yzeure/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> tapNavigationLabel(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows operations dashboard and navigates between core tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const AssOpsApp());
    await tester.pumpAndSettle();

    expect(find.text('Daily command center'), findsOneWidget);
    expect(find.text('Open work'), findsOneWidget);

    await tapNavigationLabel(tester, 'Requests');
    expect(find.text('All work'), findsOneWidget);

    await tapNavigationLabel(tester, 'Assets');
    expect(find.text('Asset board'), findsOneWidget);

    await tapNavigationLabel(tester, 'Bookings');
    expect(find.text('Appointment booking'), findsOneWidget);

    await tapNavigationLabel(tester, 'Settings');
    expect(find.text('Offline operation'), findsOneWidget);
  });

  testWidgets('creates a local operations record', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const AssOpsApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New record'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('titleField')),
      'Prepare volunteer roster',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Main hall');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'Coordination team',
    );
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'Confirm staffing for reception and setup.',
    );

    expect(find.byKey(const ValueKey('saveRecordButton')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('saveRecordButton')));
    await tester.pumpAndSettle();

    expect(find.text('Prepare volunteer roster'), findsOneWidget);
  });
}
