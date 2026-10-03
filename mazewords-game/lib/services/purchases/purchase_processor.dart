import 'language_products.dart';

enum StorePurchaseState { pending, purchased, restored, cancelled, failed }

enum PurchaseOutcome { waiting, granted, revoked, ignored, retry }

class StorePurchase {
  const StorePurchase({
    required this.productId,
    required this.proof,
    required this.state,
    required this.needsCompletion,
  });
  final String productId;

  /// Opaque store receipt/token. Never log or persist in player preferences.
  final String proof;
  final StorePurchaseState state;
  final bool needsCompletion;
}

/// The backend must verify app ID, product, store environment, purchase state,
/// ownership and revocations. A client purchase callback is not verification.
class VerifiedOwnership {
  const VerifiedOwnership(this.productId, {required this.active});
  final String productId;
  final bool active;
}

abstract interface class PurchaseVerifier {
  Future<VerifiedOwnership> verify(StorePurchase purchase);
}

abstract interface class OwnershipStore {
  /// Must atomically persist before returning; repeated grants are idempotent.
  /// A production implementation must use verified server ownership, not coins.
  Future<void> save(VerifiedOwnership ownership);
}

abstract interface class PurchaseCompletion {
  Future<void> complete(StorePurchase purchase);
}

/// Store-independent v1.1 transaction core; deliberately not wired into v1.0.
/// Both restore and purchase use the same verification and durability path.
class PurchaseProcessor {
  PurchaseProcessor(this.verifier, this.ownership, this.completion);
  final PurchaseVerifier verifier;
  final OwnershipStore ownership;
  final PurchaseCompletion completion;
  Future<void> _queue = Future<void>.value();

  Future<PurchaseOutcome> process(StorePurchase purchase) {
    final result = _queue.then((_) => _process(purchase));
    _queue = result.then<void>((_) {});
    return result;
  }

  Future<PurchaseOutcome> _process(StorePurchase purchase) async {
    if (purchase.state == StorePurchaseState.pending) {
      return PurchaseOutcome.waiting;
    }
    if (purchase.state != StorePurchaseState.purchased &&
        purchase.state != StorePurchaseState.restored) {
      return PurchaseOutcome.ignored;
    }
    if (LanguageProduct.forProduct(purchase.productId) == null ||
        purchase.proof.isEmpty) {
      return PurchaseOutcome.ignored;
    }
    try {
      final verified = await verifier.verify(purchase);
      if (verified.productId != purchase.productId) {
        return PurchaseOutcome.retry;
      }
      await ownership.save(verified);
      if (purchase.needsCompletion) await completion.complete(purchase);
      return verified.active
          ? PurchaseOutcome.granted
          : PurchaseOutcome.revoked;
    } catch (_) {
      // Network, durable-storage and completion failures must be retryable.
      // Never acknowledge a purchase whose entitlement could not be saved.
      return PurchaseOutcome.retry;
    }
  }
}
