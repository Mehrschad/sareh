// آزمونِ دودِ نشان‌ها — هر نگاره باید در هر دو پوسته بی‌خطا کشیده شود.
//
// نقاش‌ها پر از هندسه‌ی دستی‌اند و ساده‌ترین لغزش (تقسیم بر صفر، کمانِ
// وارونه) تنها هنگامِ paint خودش را نشان می‌دهد. این آزمون همه را یک بار
// روی بوم می‌کشد؛ زیبایی را چشم می‌سنجد، نشکستن را همین‌جا.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sareh/design/emblems.dart';
import 'package:sareh/design/tokens.g.dart';

void main() {
  Widget host(Widget child) => Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: child),
      );

  testWidgets('سیمرغ کشیده می‌شود', (tester) async {
    await tester.pumpWidget(
      host(
        SimorghEmblem(
          size: 160,
          colour: SarehColors.dark.action,
          accent: SarehColors.dark.achievement,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('هر هفت نگهبان با رنگِ هر دو پوسته کشیده می‌شوند', (tester) async {
    for (var khan = 1; khan <= 7; khan++) {
      for (final colour in [
        SarehKhanColors.of(khan).dark,
        SarehKhanColors.of(khan).light,
      ]) {
        await tester.pumpWidget(
          host(GuardianEmblem(khan: khan, size: 64, colour: colour)),
        );
        expect(tester.takeException(), isNull, reason: 'خانِ $khan');
      }
    }
  });

  testWidgets('خانِ بیرون از بازه نمی‌شکند', (tester) async {
    await tester.pumpWidget(
      host(GuardianEmblem(khan: 12, size: 64, colour: SarehColors.dark.action)),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('آیکن‌های شمارگان کشیده می‌شوند', (tester) async {
    await tester.pumpWidget(
      host(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FarrIcon(size: 24, colour: SarehColors.dark.achievement),
            AtashIcon(size: 24, colour: SarehColors.dark.error),
            GoharIcon(size: 24, colour: SarehColors.dark.action),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  test('رنگِ هفت خان: هفت‌تا، یکتا در هر پوسته', () {
    expect(SarehKhanColors.all, hasLength(7));
    expect(
      SarehKhanColors.all.map((k) => k.dark).toSet(),
      hasLength(7),
    );
    expect(
      SarehKhanColors.all.map((k) => k.light).toSet(),
      hasLength(7),
    );
    expect(SarehKhanColors.of(0), SarehKhanColors.all.first);
    expect(SarehKhanColors.of(3), SarehKhanColors.all[2]);
  });
}
