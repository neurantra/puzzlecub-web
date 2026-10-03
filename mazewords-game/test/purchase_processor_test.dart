import 'package:flutter_test/flutter_test.dart';
import 'package:maze_words/domain/puzzle_language.dart';
import 'package:maze_words/services/purchases/language_products.dart';
import 'package:maze_words/services/purchases/purchase_processor.dart';

class Harness implements PurchaseVerifier, OwnershipStore, PurchaseCompletion {
  final calls = <String>[];
  bool failSave = false, active = true, mismatch = false;
  @override
  Future<VerifiedOwnership> verify(StorePurchase purchase) async {
    calls.add('verify');
    return VerifiedOwnership(
      mismatch ? 'unknown' : purchase.productId,
      active: active,
    );
  }

  @override
  Future<void> save(VerifiedOwnership ownership) async {
    calls.add('save');
    if (failSave) throw StateError('disk full');
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    calls.add('complete');
  }
}

StorePurchase event(StorePurchaseState state) => StorePurchase(
  productId: LanguageProduct.all.first.productId,
  proof: 'test-proof',
  state: state,
  needsCompletion: true,
);

void main() {
  test(
    'all nine languages have unique permanent product IDs and free quotas',
    () {
      expect(
        LanguageProduct.all.map((p) => p.language).toSet(),
        PuzzleLanguage.all.map((p) => p.id).toSet(),
      );
      expect(LanguageProduct.all.map((p) => p.productId).toSet().length, 17);
      expect(LanguageProduct.forLanguage('en').paidMazesPerLevel, 130);
      expect(LanguageProduct.forLanguage('pt-BR').paidMazesPerLevel, 138);
      expect(() => LanguageProduct.forLanguage('unknown'), throwsArgumentError);
    },
  );
  test('pending and cancelled purchases never grant or complete', () async {
    final h = Harness();
    final p = PurchaseProcessor(h, h, h);
    expect(
      await p.process(event(StorePurchaseState.pending)),
      PurchaseOutcome.waiting,
    );
    expect(
      await p.process(event(StorePurchaseState.cancelled)),
      PurchaseOutcome.ignored,
    );
    expect(h.calls, isEmpty);
  });
  test('purchase and restore verify, durably save, then complete', () async {
    for (final state in [
      StorePurchaseState.purchased,
      StorePurchaseState.restored,
    ]) {
      final h = Harness();
      expect(
        await PurchaseProcessor(h, h, h).process(event(state)),
        PurchaseOutcome.granted,
      );
      expect(h.calls, ['verify', 'save', 'complete']);
    }
  });
  test(
    'failed ownership persistence is retried without completing transaction',
    () async {
      final h = Harness()..failSave = true;
      final p = PurchaseProcessor(h, h, h);
      expect(
        await p.process(event(StorePurchaseState.purchased)),
        PurchaseOutcome.retry,
      );
      expect(h.calls, ['verify', 'save']);
      h.failSave = false;
      h.calls.clear();
      expect(
        await p.process(event(StorePurchaseState.restored)),
        PurchaseOutcome.granted,
      );
      expect(h.calls, ['verify', 'save', 'complete']);
    },
  );
  test('mismatched verification never grants another language', () async {
    final h = Harness()..mismatch = true;
    expect(
      await PurchaseProcessor(
        h,
        h,
        h,
      ).process(event(StorePurchaseState.purchased)),
      PurchaseOutcome.retry,
    );
    expect(h.calls, ['verify']);
  });
  test('revocation is persisted instead of granting ownership', () async {
    final h = Harness()..active = false;
    expect(
      await PurchaseProcessor(
        h,
        h,
        h,
      ).process(event(StorePurchaseState.restored)),
      PurchaseOutcome.revoked,
    );
    expect(h.calls, ['verify', 'save', 'complete']);
  });
}
