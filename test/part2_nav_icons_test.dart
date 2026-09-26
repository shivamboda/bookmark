import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookmark/features/library/widgets/floral_bottom_nav.dart';
import 'package:bookmark/doodles/poppy_doodle.dart';
import 'package:bookmark/doodles/tulip_doodle.dart';
import 'package:bookmark/doodles/daisy_doodle.dart';
import 'package:bookmark/doodles/leaf_sprig_doodle.dart';

void main() {
  group('Part 2: Bottom Nav Icons Performance & Offline Integrity', () {
    test('Nav icon assets are locally bundled and well below size threshold (< 25 KB each)', () {
      final icons = [
        'assets/icons/nav_poppy.png',
        'assets/icons/nav_tulip.png',
        'assets/icons/nav_daisy.png',
        'assets/icons/nav_sprig.png',
      ];

      int totalBytes = 0;
      for (final path in icons) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'Icon $path must exist in local asset bundle');
        final bytes = file.lengthSync();
        totalBytes += bytes;
        // Each icon should be optimized under 25 KB (down from the 1.2MB - 1.95MB regression)
        expect(bytes, lessThan(25 * 1024),
            reason: '$path is $bytes bytes, expected < 25 KB');
      }

      // Total of all 4 icons combined must be under 75 KB (was 4,819 KB / ~4.8 MB!)
      expect(totalBytes, lessThan(75 * 1024),
          reason: 'Total size $totalBytes bytes must be under 75 KB');
    });

    testWidgets('FloralBottomNav renders watercolor icons with cache dimensions and proper layout', (tester) async {
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

      // Verify all 4 tab labels are present
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Wishlist'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify Image widgets are rendered with local AssetImage
      final imageFinders = find.byType(Image);
      expect(imageFinders, findsNWidgets(4));

      for (final elem in tester.widgetList<Image>(imageFinders)) {
        expect(elem.image is ResizeImage, isTrue);
        final resizeImage = elem.image as ResizeImage;
        expect(resizeImage.imageProvider is AssetImage, isTrue);
        expect(elem.width, 26);
        expect(elem.height, 26);
        // Verify cache dimensions are explicitly set to prevent decoding full bitmaps
        expect(resizeImage.width, 104);
        expect(resizeImage.height, 104);
      }
    });

    testWidgets('CustomPainter vector doodles are fully intact and can be rendered', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PoppyDoodle(size: 26, showStem: false),
                TulipDoodle(size: 26, showStem: false),
                DaisyDoodle(size: 26, showStem: false),
                LeafSprigDoodle(size: 26),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(PoppyDoodle), findsOneWidget);
      expect(find.byType(TulipDoodle), findsOneWidget);
      expect(find.byType(DaisyDoodle), findsOneWidget);
      expect(find.byType(LeafSprigDoodle), findsOneWidget);
    });
  });
}
