import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookmark/doodles/poppy_doodle.dart';
import 'package:bookmark/doodles/tulip_doodle.dart';
import 'package:bookmark/doodles/daisy_doodle.dart';
import 'package:bookmark/doodles/leaf_sprig_doodle.dart';
import 'package:bookmark/features/library/widgets/floral_bottom_nav.dart';
import 'package:bookmark/core/theme/palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bottom Navigation Bar - Four Botanical Tab Icons', () {
    testWidgets('All four botanical icons render side-by-side with exact 26x26 dimensions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: FloralPalette.softIvory,
            body: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  PoppyDoodle(
                    key: ValueKey('tab_icon_poppy'),
                    size: 26,
                    showStem: false,
                    petalColor: FloralPalette.rosePetal,
                  ),
                  TulipDoodle(
                    key: ValueKey('tab_icon_tulip'),
                    size: 26,
                    showStem: false,
                    petalColor: FloralPalette.rosePetal,
                  ),
                  DaisyDoodle(
                    key: ValueKey('tab_icon_daisy'),
                    size: 26,
                    showStem: false,
                  ),
                  LeafSprigDoodle(
                    key: ValueKey('tab_icon_leaf_sprig'),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify all 4 icons exist
      final poppyFinder = find.byKey(const ValueKey('tab_icon_poppy'));
      final tulipFinder = find.byKey(const ValueKey('tab_icon_tulip'));
      final daisyFinder = find.byKey(const ValueKey('tab_icon_daisy'));
      final leafFinder = find.byKey(const ValueKey('tab_icon_leaf_sprig'));

      expect(poppyFinder, findsOneWidget);
      expect(tulipFinder, findsOneWidget);
      expect(daisyFinder, findsOneWidget);
      expect(leafFinder, findsOneWidget);

      // Verify exact sizes
      expect(tester.getSize(poppyFinder), const Size(26, 26));
      expect(tester.getSize(tulipFinder), const Size(26, 26));
      expect(tester.getSize(daisyFinder), const Size(26, 26));
      expect(tester.getSize(leafFinder), const Size(26, 26));
    });

    testWidgets('FloralBottomNav renders all four tabs with respective botanical doodle icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: FloralBottomNav(
              currentIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(PoppyDoodle), findsOneWidget);
      expect(find.byType(TulipDoodle), findsOneWidget);
      expect(find.byType(DaisyDoodle), findsOneWidget);
      expect(find.byType(LeafSprigDoodle), findsOneWidget);

      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Wishlist'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
