import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:insta_reel_downloader/presentation/app.dart';

void main() {
  testWidgets('bootstraps the navigation scaffold and home actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: InstaReelDownloaderApp()),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Insta Reel Downloader'), findsOneWidget);

    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);

    await tester.enterText(textField, 'https://instagram.com/reel/demo');
    await tester.tap(find.text('Download reel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Queued'), findsWidgets);

    await tester.tap(find.text('Downloads'));
    await tester.pumpAndSettle();

    expect(find.text('Active downloads'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
  });
}
