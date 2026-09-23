import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookmark/main.dart';

void main() {
  testWidgets('Bookmark initial smoke test', (WidgetTester tester) async {
    // Build BookmarkApp wrapped in ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: BookmarkApp(),
      ),
    );

    // Verify app title appears
    expect(find.text('Bookmark'), findsOneWidget);
  });
}
