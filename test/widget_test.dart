import 'package:flutter_test/flutter_test.dart';
import 'package:social_media_app/main.dart';

void main() {
  testWidgets('Social Media App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SocialMediaApp());

    expect(find.byType(SocialMediaApp), findsOneWidget);
  });
}