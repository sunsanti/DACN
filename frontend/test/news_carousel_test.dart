import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/news_ui.dart';
import 'package:frontend/models/news.dart';

News _n(int i) => News(id: i, title: 'Tin $i', url: 'https://example.com/$i', imagePath: '', createdAt: DateTime(2026));

Future<void> _pump(WidgetTester t, int count) => t.pumpWidget(MaterialApp(
      home: Scaffold(body: NewsCarousel([for (var i = 0; i < count; i++) _n(i)])),
    ));

int _page(WidgetTester t) => t.widget<PageView>(find.byType(PageView)).controller!.page!.round();

void main() {
  testWidgets('arrows move pages and wrap around at both ends', (t) async {
    await _pump(t, 3);
    await t.tap(find.byTooltip('Tin sau'));
    await t.pumpAndSettle();
    expect(_page(t), 1);

    await t.tap(find.byTooltip('Tin trước'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Tin trước')); // from first → last
    await t.pumpAndSettle();
    expect(_page(t), 2);

    await t.tap(find.byTooltip('Tin sau')); // from last → first
    await t.pumpAndSettle();
    expect(_page(t), 0);
    await t.pumpWidget(const SizedBox()); // dispose → cancel the auto-play timer
  });

  testWidgets('a single news item has no arrows', (t) async {
    await _pump(t, 1);
    expect(find.byTooltip('Tin sau'), findsNothing);
    expect(find.byTooltip('Tin trước'), findsNothing);
  });
}
