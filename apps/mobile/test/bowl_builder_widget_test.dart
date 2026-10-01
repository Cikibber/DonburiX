import 'dart:async';

import 'package:donburix/app.dart';
import 'package:donburix/features/bowl_builder/data/demo_bowl_repository.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_models.dart';
import 'package:donburix/features/bowl_builder/domain/bowl_repository.dart';
import 'package:donburix/features/bowl_builder/state/bowl_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class ControlledBowlRepository implements BowlRepository {
  final loading = Completer<List<Ingredient>>();
  final submission = Completer<CartEntry>();
  int loadCount = 0;
  int submitCount = 0;
  BowlDraft? receivedDraft;

  @override
  Future<List<Ingredient>> loadIngredients() {
    loadCount++;
    return loadCount == 1 ? loading.future : Future.value(demoIngredients);
  }

  @override
  Future<CartEntry> addToCart(BowlDraft draft) {
    submitCount++;
    receivedDraft = draft;
    return submission.future;
  }
}

Future<void> mount(
  WidgetTester tester,
  ControlledBowlRepository repository,
) async {
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [bowlRepositoryProvider.overrideWithValue(repository)],
      child: const DonburiXApp(),
    ),
  );
}

Future<void> load(
  WidgetTester tester,
  ControlledBowlRepository repository,
) async {
  await mount(tester, repository);
  repository.loading.complete(demoIngredients);
  await tester.pumpAndSettle();
}

Future<void> selectBowl(WidgetTester tester) async {
  for (final id in ['rice', 'chicken', 'teriyaki', 'egg']) {
    final finder = find.byKey(Key('ingredient-$id'));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }
}

Future<void> submit(WidgetTester tester) async {
  final button = find.byKey(const Key('submit-button'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets('initial loading shows progress and no form or submit button', (
    tester,
  ) async {
    final repository = ControlledBowlRepository();
    await mount(tester, repository);
    expect(find.byKey(const Key('initial-loading')), findsOneWidget);
    expect(find.text('Menyiapkan pilihan bahan…'), findsOneWidget);
    expect(find.byType(Form), findsNothing);
    expect(find.byKey(const Key('submit-button')), findsNothing);
  });

  testWidgets('successful load shows ingredients and recalculates the price', (
    tester,
  ) async {
    final repository = ControlledBowlRepository();
    await load(tester, repository);
    expect(find.text('Bowl Anda,\nrasa Anda.'), findsOneWidget);
    await selectBowl(tester);
    expect(
      tester.widget<Text>(find.byKey(const Key('bowl-total'))).data,
      'Rp 25.000',
    );
    await tester.enterText(find.byKey(const Key('quantity-input')), '2');
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('bowl-total'))).data,
      'Rp 50.000',
    );
  });

  testWidgets('empty catalog shows empty state without checkout controls', (
    tester,
  ) async {
    final repository = ControlledBowlRepository();
    await mount(tester, repository);
    repository.loading.complete([]);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada pilihan bahan'), findsOneWidget);
    expect(find.text('Muat Ulang'), findsOneWidget);
    expect(find.byType(Form), findsNothing);
  });

  testWidgets('load error shows retry and retry recovers to the form', (
    tester,
  ) async {
    final repository = ControlledBowlRepository();
    await mount(tester, repository);
    repository.loading.completeError(
      const BowlFailure('Jaringan sedang bermasalah.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jaringan sedang bermasalah.'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.byType(Form), findsOneWidget);
    expect(repository.loadCount, 2);
  });

  testWidgets(
    'missing ingredient selections show validation and do not submit',
    (tester) async {
      final repository = ControlledBowlRepository();
      await load(tester, repository);
      await submit(tester);
      for (final label in ['base', 'protein', 'saus', 'add-on']) {
        expect(find.text('Pilih $label terlebih dahulu.'), findsOneWidget);
      }
      expect(repository.submitCount, 0);
    },
  );

  testWidgets('invalid quantities are rejected without submission', (
    tester,
  ) async {
    final repository = ControlledBowlRepository();
    await load(tester, repository);
    await selectBowl(tester);
    for (final value in ['', '0', '11', '1.5', 'abc']) {
      await tester.enterText(find.byKey(const Key('quantity-input')), value);
      await submit(tester);
      expect(
        find.text('Jumlah harus bilangan bulat antara 1 dan 10.'),
        findsOneWidget,
      );
    }
    expect(repository.submitCount, 0);
  });

  testWidgets('overlong kitchen note is rejected', (tester) async {
    final repository = ControlledBowlRepository();
    await load(tester, repository);
    await selectBowl(tester);
    await tester.enterText(
      find.byKey(const Key('note-input')),
      List.filled(121, 'a').join(),
    );
    await submit(tester);
    expect(find.text('Catatan maksimal 120 karakter.'), findsOneWidget);
    expect(repository.submitCount, 0);
  });

  testWidgets('sold-out ingredient cannot be selected', (tester) async {
    final repository = ControlledBowlRepository();
    await load(tester, repository);
    final chip = tester.widget<ChoiceChip>(
      find.byKey(const Key('ingredient-beef')),
    );
    expect(chip.onSelected, isNull);
    expect(find.text('Sapi yakiniku · Habis'), findsOneWidget);
  });

  testWidgets('quantity exceeding ingredient stock is rejected', (
    tester,
  ) async {
    final repository = ControlledBowlRepository();
    await load(tester, repository);
    await selectBowl(tester);
    await tester.tap(find.byKey(const Key('ingredient-tofu')));
    await tester.enterText(find.byKey(const Key('quantity-input')), '7');
    await submit(tester);
    expect(
      find.text('Stok Tahu crispy tidak cukup untuk 7 porsi.'),
      findsOneWidget,
    );
    expect(repository.submitCount, 0);
  });

  testWidgets(
    'submit locks form and prevents both double tap and reentrant submission',
    (tester) async {
      final repository = ControlledBowlRepository();
      await load(tester, repository);
      await selectBowl(tester);
      await submit(tester);
      expect(find.byKey(const Key('submit-loading')), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('submit-button')),
      );
      expect(button.onPressed, isNull);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('quantity-input')))
            .enabled,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('submit-button')));
      final context = tester.element(find.byType(DonburiXApp));
      await ProviderScope.containerOf(
        context,
      ).read(bowlBuilderProvider.notifier).submit();
      expect(repository.submitCount, 1);
      repository.submission.complete(
        CartEntry(id: 'test-cart', bowl: repository.receivedDraft!),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('1 porsi berhasil ditambahkan ke keranjang.'),
        findsOneWidget,
      );
      expect(find.text('Keranjang (1)'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('submit-button')))
            .onPressed,
        isNotNull,
      );
      await tester.ensureVisible(find.byKey(const Key('cart-button')));
      await tester.tap(find.byKey(const Key('cart-button')));
      await tester.pumpAndSettle();
      expect(find.text('Keranjang Anda'), findsOneWidget);
      expect(
        find.text('Nasi putih · Ayam teriyaki · Saus teriyaki · Telur'),
        findsOneWidget,
      );
    },
  );

  testWidgets('submit failure retains inputs and allows a second attempt', (
    tester,
  ) async {
    final repository = ControlledBowlRepository();
    await load(tester, repository);
    await selectBowl(tester);
    await tester.enterText(find.byKey(const Key('note-input')), 'Saus dipisah');
    await submit(tester);
    repository.submission.completeError(
      const BowlFailure('Stok berubah. Silakan periksa lagi.'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stok berubah. Silakan periksa lagi.'), findsOneWidget);
    expect(find.text('Saus dipisah'), findsOneWidget);
    expect(find.text('Keranjang (0)'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('submit-button')))
          .onPressed,
      isNotNull,
    );
    await submit(tester);
    await tester.pumpAndSettle();
    expect(repository.submitCount, 2);
  });

  testWidgets('narrow mobile screen has no layout exception', (tester) async {
    final repository = ControlledBowlRepository();
    await load(tester, repository);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await selectBowl(tester);
    await submit(tester);
    repository.submission.complete(
      CartEntry(id: 'mobile-cart', bowl: repository.receivedDraft!),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Keranjang (1)'), findsOneWidget);
  });
}
