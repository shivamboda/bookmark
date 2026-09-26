import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookmark/features/library/widgets/floral_bottom_nav.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bottom Navigation Bar - Four Watercolor Botanical Tab Icons', () {
    testWidgets('FloralBottomNav renders all four tabs with respective botanical watercolor icons', (tester) async {
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

      // Verify all 4 image assets exist
      final images = find.byType(Image);
      expect(images, findsNWidgets(4));

      // Check asset paths
      final poppyImage = tester.widget<Image>(images.at(0));
      expect((poppyImage.image as AssetImage).assetName, 'assets/icons/nav_poppy.png');

      final tulipImage = tester.widget<Image>(images.at(1));
      expect((tulipImage.image as AssetImage).assetName, 'assets/icons/nav_tulip.png');

      final daisyImage = tester.widget<Image>(images.at(2));
      expect((daisyImage.image as AssetImage).assetName, 'assets/icons/nav_daisy.png');

      final sprigImage = tester.widget<Image>(images.at(3));
      expect((sprigImage.image as AssetImage).assetName, 'assets/icons/nav_sprig.png');

      // Verify labels
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Wishlist'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
