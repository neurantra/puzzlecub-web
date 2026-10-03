import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../data/player_store.dart';
import '../domain/puzzle_language.dart';
import '../services/purchases/purchase_catalog.dart';
import '../services/purchases/purchase_service.dart';
import 'age_information.dart';

class LanguageStoreScreen extends StatefulWidget {
  const LanguageStoreScreen({
    super.key,
    required this.store,
    required this.purchases,
  });
  final PlayerStore store;
  final PurchaseService purchases;
  @override
  State<LanguageStoreScreen> createState() => _LanguageStoreScreenState();
}

class _LanguageStoreScreenState extends State<LanguageStoreScreen> {
  String? message;
  bool loading = false;
  PurchaseService get purchases => widget.purchases;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<bool> _allowed() async =>
      widget.store.adult || await ageParentGate(context);
  Future<void> _load() async {
    if (!await _allowed() || !mounted) return;
    setState(() => loading = true);
    try {
      await purchases.initialize();
    } catch (_) {
      message = 'Could not connect to the store. Please try again.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<String?> _choose(PurchaseTier tier) async {
    final other = tier == PurchaseTier.first
        ? PurchaseTier.second
        : PurchaseTier.first;
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose your language'),
        children: [
          for (final language in PuzzleLanguage.all)
            if (!(purchases.access.owns(other) &&
                purchases.languageFor(other) == language.id))
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, language.id),
                child: Text('${language.flag} ${language.name}'),
              ),
        ],
      ),
    );
  }

  Future<void> _purchase(PurchaseTier tier) async {
    if (!await _allowed() || !mounted) return;
    final language = tier == PurchaseTier.all ? null : await _choose(tier);
    if (!mounted || (tier != PurchaseTier.all && language == null)) return;
    try {
      if (purchases.access.owns(tier)) {
        await purchases.selectRestoredLanguage(tier, language!);
      } else {
        await purchases.buy(tier, language: language);
      }
      if (mounted) {
        setState(
          () => message = purchases.access.owns(tier)
              ? 'Unlocked. Choose your language in Download languages to play.'
              : 'Purchase awaiting approval. Access unlocks when payment completes.',
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final cancelled =
          PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError;
      setState(
        () => message = cancelled
            ? null
            : 'Purchase not completed. If payment is pending, access will unlock after approval. You can also try Restore purchases.',
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Could not complete this purchase. Check your connection and purchase prerequisites, then try again.',
        );
      }
    }
  }

  Future<void> _restore() async {
    if (!await _allowed() || !mounted) return;
    try {
      await purchases.restore();
      if (mounted) {
        setState(
          () => message = purchases.access.adFree
              ? 'Purchases restored. Choose a language for any unassigned pack below.'
              : 'No purchases were found for this store account.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => message = 'Could not restore purchases. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: purchases,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Unlock languages')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'More words. No ads.',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Text(
              'Every unlocked language includes 150 mazes each in Easy, Medium and Hard. One-time purchases, with unlimited replay. Any purchase removes ads throughout the app.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Free play includes 10 mazes per level in one chosen language.',
            ),
            if (loading || purchases.busy) const LinearProgressIndicator(),
            if (message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(message!),
              ),
            for (final tier in PurchaseTier.values) _card(tier),
            TextButton(
              onPressed: purchases.busy || loading ? null : _restore,
              child: const Text('Restore purchases'),
            ),
            if (!purchases.ready ||
                purchases.listings.length < PurchaseTier.values.length)
              TextButton(
                onPressed: purchases.busy || loading ? null : _load,
                child: const Text('Retry store connection'),
              ),
            const SizedBox(height: 12),
            const Text(
              'Restore uses your Apple or Google store account. Language selections stay on this device; if missing after a reinstall, you can choose again. Purchases do not automatically transfer between Apple and Google accounts.',
            ),
          ],
        ),
      ),
    ),
  );

  Widget _card(PurchaseTier tier) {
    final owned = purchases.access.owns(tier);
    final all = purchases.access.owns(PurchaseTier.all);
    final selected = purchases.languageFor(tier);
    final needsSelection =
        owned && !all && tier != PurchaseTier.all && selected == null;
    final listing = purchases.listings
        .where((p) => p.id == tier.productId)
        .firstOrNull;
    final prerequisite =
        tier != PurchaseTier.first &&
        !purchases.access.owns(PurchaseTier.first) &&
        !owned &&
        !all;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tier.title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              tier == PurchaseTier.all
                  ? 'Unlock every remaining language, including future additions.'
                  : 'Unlock one language of your choice.',
            ),
            if (owned && selected != null && tier != PurchaseTier.all)
              Text(PuzzleLanguage.of(selected).name),
            if (prerequisite)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Requires First Language'),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: loading || purchases.busy
                  ? null
                  : needsSelection
                  ? () => _purchase(tier)
                  : purchases.canBuy(tier)
                  ? () => _purchase(tier)
                  : null,
              child: Text(
                needsSelection
                    ? 'Choose restored language'
                    : owned || all
                    ? 'Owned'
                    : prerequisite
                    ? 'Buy First Language first'
                    : listing == null
                    ? 'Unavailable'
                    : 'Unlock · ${listing.price}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
