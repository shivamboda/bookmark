import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookmark/features/library/widgets/floral_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pill-Shaped Bottom Navigation Bar Tests', () {
    tearDown(() {
      FloralBottomNav.shape = FloralNavShape.floatingPill;
    });

    testWidgets('floatingPill shape has true stadium radius, margin insets, frosted glass, and >= 44px tap targets', (tester) async {
      FloralBottomNav.shape = FloralNavShape.floatingPill;
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Content')),
            bottomNavigationBar: FloralBottomNav(
              currentIndex: selectedTab,
              onTabSelected: (index) {
                selectedTab = index;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify RepaintBoundary & BackdropFilter with 12px blur
      final repaintBoundaries = find.descendant(
        of: find.byType(FloralBottomNav),
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaries, findsWidgets);

      final backdropFinder = find.descendant(
        of: find.byType(FloralBottomNav),
        matching: find.byType(BackdropFilter),
      );
      expect(backdropFinder, findsOneWidget);

      // 2. Verify ClipRRect with radius 33px (half-height of 66px)
      final clipRRectFinder = find.descendant(
        of: find.byType(FloralBottomNav),
        matching: find.byType(ClipRRect),
      );
      expect(clipRRectFinder, findsOneWidget);
      final clipRRect = tester.widget<ClipRRect>(clipRRectFinder);
      expect(clipRRect.borderRadius, equals(BorderRadius.circular(33.0)));

      // 3. Verify 16px horizontal margins from screen edges
      final paddingFinder = find.descendant(
        of: find.byType(FloralBottomNav),
        matching: find.byType(Padding),
      ).first;
      final padding = tester.widget<Padding>(paddingFinder);
      expect((padding.padding as EdgeInsets).left, equals(16.0));
      expect((padding.padding as EdgeInsets).right, equals(16.0));

      // 4. Verify all 4 tab items exist and tap targets are >= 44px
      final tabLabels = ['Library', 'Wishlist', 'Stats', 'Settings'];
      for (int i = 0; i < tabLabels.length; i++) {
        final labelFinder = find.text(tabLabels[i]);
        expect(labelFinder, findsOneWidget);

        final inkWellFinder = find.ancestor(
          of: labelFinder,
          matching: find.byType(InkWell),
        );
        expect(inkWellFinder, findsOneWidget);

        final inkWellSize = tester.getSize(inkWellFinder);
        expect(inkWellSize.width, greaterThanOrEqualTo(44.0), reason: '${tabLabels[i]} width must be >= 44px');
        expect(inkWellSize.height, greaterThanOrEqualTo(44.0), reason: '${tabLabels[i]} height must be >= 44px');
      }

      // 5. Verify tapping tabs updates selection
      await tester.tap(find.text('Wishlist'));
      expect(selectedTab, equals(1));

      await tester.tap(find.text('Stats'));
      expect(selectedTab, equals(2));

      await tester.tap(find.text('Settings'));
      expect(selectedTab, equals(3));
    });

    testWidgets('dockedSoftRounded shape renders with 28px top corner radius', (tester) async {
      FloralBottomNav.shape = FloralNavShape.dockedSoftRounded;
      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Content')),
            bottomNavigationBar: FloralBottomNav(
              currentIndex: selectedTab,
              onTabSelected: (index) {
                selectedTab = index;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify ClipRRect with 28px vertical top radius
      final clipRRectFinder = find.descendant(
        of: find.byType(FloralBottomNav),
        matching: find.byType(ClipRRect),
      );
      expect(clipRRectFinder, findsOneWidget);
      final clipRRect = tester.widget<ClipRRect>(clipRRectFinder);
      expect(
        clipRRect.borderRadius,
        equals(const BorderRadius.vertical(top: Radius.circular(28.0))),
      );

      // Verify all tabs clickable
      await tester.tap(find.text('Wishlist'));
      expect(selectedTab, equals(1));
    });
  });
}
