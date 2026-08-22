// آزمونِ دودِ نشان‌ها — هر نگاره باید در هر دو پوسته بی‌خطا کشیده شود.
//
// نقاش‌ها پر از هندسه‌ی دستی‌اند و ساده‌ترین لغزش (تقسیم بر صفر، کمانِ
// وارونه) تنها هنگامِ paint خودش را نشان می‌دهد. این آزمون همه را یک بار
// روی بوم می‌کشد؛ زیبایی را چشم می‌سنجد، نشکستن را همین‌جا.

import 'dart:math' as math;

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
        SimorghEmblem(size: 160, colour: SarehColors.dark.action),
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

  group('هندسه‌ی نشان‌ها', () {
    test('هر نقش دقیقاً کادرِ خودش را پر می‌کند', () {
      for (final name in emblemNames) {
        final bounds = emblemPath(name).getBounds();
        expect(bounds.isEmpty, isFalse, reason: name);
        // `_fit` هر نقش را هم‌مقیاس در کادرِ ۱۰۰ می‌نشاند، پس بزرگ‌ترین
        // بُعد همیشه ۱۰۰ است. بی این، مختصاتِ دستی از کادر بیرون می‌زدند
        // و کسی نمی‌فهمید — دمِ سیمرغ تا ۱۱۸ می‌رفت و بالِ فَرّ تا ۱۳۶.
        expect(
          math.max(bounds.width, bounds.height),
          closeTo(100, 0.5),
          reason: name,
        );
        expect(bounds.left, greaterThanOrEqualTo(-0.5), reason: name);
        expect(bounds.top, greaterThanOrEqualTo(-0.5), reason: name);
        expect(bounds.right, lessThanOrEqualTo(100.5), reason: name);
        expect(bounds.bottom, lessThanOrEqualTo(100.5), reason: name);
      }
    });

    test('نقشِ باریک هم آن‌قدر پهن هست که ریز ننماید', () {
      for (final name in emblemNames) {
        final bounds = emblemPath(name).getBounds();
        expect(
          math.min(bounds.width, bounds.height),
          greaterThan(50),
          reason: '$name کشیده‌تر از ۲:۱ است',
        );
      }
    });

    test('سوراخ‌ها واقعاً بریده‌اند', () {
      // میانِ حلقه‌ی خورشیدِ «شیر و خورشید» باید تهی باشد.
      expect(
        emblemPath('shirokhorshid').contains(const Offset(80, 24)),
        isFalse,
      );
    });

    test('آنچه پس از سوراخ کشیده شده، پاک نشده', () {
      // این دو همان جفتی‌اند که پیاده‌سازیِ ساده‌ی «همه‌ی تنه منهای همه‌ی
      // سوراخ» از میان می‌برد — و بی این آزمون، بی‌صدا برمی‌گردند.
      expect(
        emblemPath('rosette').contains(const Offset(50, 50)),
        isTrue,
        reason: 'پرگِ میانیِ گل پس از سوراخ کشیده می‌شود',
      );
      expect(
        emblemPath('guardian-7').contains(const Offset(41, 74)),
        isTrue,
        reason: 'نیشِ دیو سپید روی سوراخِ دهان می‌نشیند',
      );
    });
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
