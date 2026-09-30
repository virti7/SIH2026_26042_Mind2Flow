import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maatribhasha/app/app.dart';
import 'package:maatribhasha/app/di/injection.dart';
import 'package:maatribhasha/app/router/app_router.dart';
import 'package:maatribhasha/app/router/route_names.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    await setupDependencyInjection();
  });

  testWidgets('Test full navigation flow and pop', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 823);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaatribhashaApp());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // 1. Go to Home
    appRouter.go(AppRoutes.home);
    await tester.pumpAndSettle();

    // 2. Push Lesson Planner from Home (simulating Start Lesson button)
    appRouter.push(AppRoutes.lessonPlanner);
    await tester.pumpAndSettle();

    // 3. Pop Lesson Planner back to Home
    appRouter.pop();
    await tester.pumpAndSettle();

    // 4. Switch tabs via bottom nav
    appRouter.go(AppRoutes.teach);
    await tester.pumpAndSettle();

    appRouter.go(AppRoutes.translate);
    await tester.pumpAndSettle();

    appRouter.go(AppRoutes.progress);
    await tester.pumpAndSettle();

    appRouter.go(AppRoutes.settings);
    await tester.pumpAndSettle();

    // 5. Teach drilldown
    appRouter.go(AppRoutes.teach);
    await tester.pumpAndSettle();

    appRouter.push('/teach/class/2');
    await tester.pumpAndSettle();

    appRouter.pop();
    await tester.pumpAndSettle();

    appRouter.push('/teach/subject/math');
    await tester.pumpAndSettle();

    appRouter.pop();
    await tester.pumpAndSettle();

    appRouter.push(AppRoutes.nipunOutcomes);
    await tester.pumpAndSettle();

    appRouter.push(AppRoutes.lessonPlanner);
    await tester.pumpAndSettle();

    appRouter.push('/teach/lesson/lp_m2_1_4');
    await tester.pumpAndSettle();

    appRouter.pop();
    await tester.pumpAndSettle();
    appRouter.pop();
    await tester.pumpAndSettle();
    appRouter.pop();
    await tester.pumpAndSettle();

    // 6. Literacy Flow: Teach -> Foundational Literacy -> Oral Language -> Activity -> Back
    appRouter.go(AppRoutes.teach);
    await tester.pumpAndSettle();

    appRouter.push(AppRoutes.literacy);
    await tester.pumpAndSettle();

    appRouter.push(AppRoutes.oralLanguage);
    await tester.pumpAndSettle();

    appRouter.push('/literacy/activity/act_003');
    await tester.pumpAndSettle();

    appRouter.pop();
    await tester.pumpAndSettle();

    appRouter.pop();
    await tester.pumpAndSettle();

    // 7. Literacy Flow: Foundational Literacy -> Decoding -> Back
    appRouter.push(AppRoutes.decoding);
    await tester.pumpAndSettle();

    appRouter.pop();
    await tester.pumpAndSettle();

    appRouter.pop();
    await tester.pumpAndSettle();
  });
}
