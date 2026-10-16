import 'package:donburix/app.dart';
import 'package:donburix/features/bowl_builder/state/bowl_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'bowl_builder_widget_test.dart' as shared;

Future<void> loadWithOneBowl(
  WidgetTester tester,
  shared.ControlledBowlRepository repository,
) async {
  await shared.load(tester, repository);
  await shared.selectBowl(tester);
  await shared.submit(tester);
  repository.submission.complete(
    shared.cartEntryForTest(repository.receivedDraft!),
  );
  await tester.pumpAndSettle();
}

Future<void> openCart(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(const Key('cart-button')));
  await tester.tap(find.byKey(const Key('cart-button')));
  await tester.pumpAndSettle();
}

String cartTotalText(WidgetTester tester) {
  return tester.widget<Text>(find.byKey(const Key('cart-total'))).data!;
}

void main() {
  testWidgets('AC1 cart shows item, quantity, note, and subtotal', (
    tester,
  ) async {
    final repository = shared.ControlledBowlRepository();
    await loadWithOneBowl(tester, repository);
    await openCart(tester);

    expect(find.text('Keranjang Anda'), findsOneWidget);
    expect(
      find.text('Nasi putih · Ayam teriyaki · Saus teriyaki · Telur'),
      findsOneWidget,
    );
    expect(find.text('1 porsi'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-subtotal-local-1'))).data,
      'Rp 25.000',
    );
    expect(cartTotalText(tester), 'Rp 25.000');
    expect(find.text('Lanjut ke Checkout'), findsOneWidget);
  });

  testWidgets('AC2 stepper updates quantity and total reactively', (
    tester,
  ) async {
    final repository = shared.ControlledBowlRepository();
    await loadWithOneBowl(tester, repository);
    await openCart(tester);

    await tester.tap(find.byKey(const Key('cart-increase-local-1')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-quantity-local-1'))).data,
      '2',
    );
    expect(cartTotalText(tester), 'Rp 50.000');

    await tester.tap(find.byKey(const Key('cart-decrease-local-1')));
    await tester.pump();
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-quantity-local-1'))).data,
      '1',
    );
    expect(cartTotalText(tester), 'Rp 25.000');
  });

  testWidgets('AC3 quantity below 1 is rejected with the old value kept', (
    tester,
  ) async {
    final repository = shared.ControlledBowlRepository();
    await loadWithOneBowl(tester, repository);
    await openCart(tester);

    await tester.tap(find.byKey(const Key('cart-decrease-local-1')));
    await tester.pump();

    expect(find.byKey(const Key('cart-error')), findsOneWidget);
    expect(
      find.text('Jumlah harus bilangan bulat antara 1 dan 10.'),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-quantity-local-1'))).data,
      '1',
    );
    expect(cartTotalText(tester), 'Rp 25.000');
  });

  testWidgets('AC3 quantity above stock is rejected with the old value kept', (
    tester,
  ) async {
    final repository = shared.ControlledBowlRepository();
    await loadWithOneBowl(tester, repository);
    await openCart(tester);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(DonburiXApp)),
    );
    container
        .read(bowlBuilderProvider.notifier)
        .updateCartQuantity('local-1', 11);
    await tester.pump();

    expect(
      find.text('Jumlah harus bilangan bulat antara 1 dan 10.'),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-quantity-local-1'))).data,
      '1',
    );
    expect(cartTotalText(tester), 'Rp 25.000');
  });

  testWidgets(
    'AC4 removing the last item shows the empty state without checkout',
    (tester) async {
      final repository = shared.ControlledBowlRepository();
      await loadWithOneBowl(tester, repository);
      await openCart(tester);

      await tester.tap(find.byKey(const Key('cart-remove-local-1')));
      await tester.pump();

      expect(find.text('Keranjang masih kosong'), findsOneWidget);
      expect(find.text('Lanjut ke Checkout'), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Keranjang (0)'), findsOneWidget);
    },
  );

  testWidgets('AC5 items stay independent when one is removed', (tester) async {
    final repository = shared.ControlledBowlRepository();
    await loadWithOneBowl(tester, repository);
    repository.submission = shared.newSubmissionForTest();
    await shared.selectBowl(tester);
    await tester.enterText(find.byKey(const Key('quantity-input')), '2');
    await shared.submit(tester);
    repository.submission.complete(
      shared.cartEntryForTest(repository.receivedDraft!, id: 'local-2'),
    );
    await tester.pumpAndSettle();
    await openCart(tester);

    expect(cartTotalText(tester), 'Rp 75.000');

    await tester.tap(find.byKey(const Key('cart-remove-local-1')));
    await tester.pump();

    expect(find.byKey(const Key('cart-item-local-2')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('cart-quantity-local-2'))).data,
      '2',
    );
    expect(cartTotalText(tester), 'Rp 50.000');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Keranjang (2)'), findsOneWidget);
  });
}
