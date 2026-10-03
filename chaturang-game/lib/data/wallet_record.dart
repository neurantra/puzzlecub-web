import 'dart:convert';

/// A bank that has been debited locally but whose vault write has not yet
/// been confirmed. Replayed at launch — see [WalletService.pendingBanks].
class PendingBank {
  const PendingBank({
    required this.transferId,
    required this.amount,
    this.attempts = 0,
  });

  final String transferId;
  final int amount;

  /// Failed replays so far. Distinguishes "not yet" from "never": a
  /// transient failure clears on the next launch, while something that will
  /// never clear — the vault gone, this uid no longer a member — otherwise
  /// retries silently forever with the player's coins still debited.
  final int attempts;

  /// Failed replays after which a bank is treated as stuck and surfaced to
  /// the player rather than retried in silence.
  static const int stuckAfter = 5;

  bool get isStuck => attempts >= stuckAfter;

  PendingBank get retried => PendingBank(
    transferId: transferId,
    amount: amount,
    attempts: attempts + 1,
  );

  Map<String, Object?> toJson() => {
    't': transferId,
    'a': amount,
    'n': attempts,
  };

  static PendingBank? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final t = raw['t'], a = raw['a'];
    if (t is! String || t.isEmpty || a is! int || a <= 0) return null;
    final n = raw['n'];
    return PendingBank(
      transferId: t,
      amount: a,
      attempts: n is int && n >= 0 ? n : 0,
    );
  }
}

/// A withdrawal that has been credited locally. [acked] records whether the
/// vault has been told, which is what makes safe pruning possible: see
/// [WalletRecord.pruned].
class AppliedWithdrawal {
  const AppliedWithdrawal({required this.transferId, required this.acked});

  final String transferId;
  final bool acked;

  AppliedWithdrawal ackedCopy() =>
      AppliedWithdrawal(transferId: transferId, acked: true);

  Map<String, Object?> toJson() => {'t': transferId, 'k': acked};

  static AppliedWithdrawal? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final t = raw['t'];
    if (t is! String || t.isEmpty) return null;
    return AppliedWithdrawal(transferId: t, acked: raw['k'] == true);
  }
}

/// The player's coin balance together with the two lists that make coin
/// movement across the shared vault recoverable.
///
/// Balance and journal live in one record, and therefore in one
/// `setString`, because the guarantee they provide is that they move
/// together. Two separate preference keys would be two writes with a
/// crash window between them, which loses or duplicates coins; that is
/// not a discipline that can be maintained by care, so it is prevented by
/// structure. This is also why coins are not part of `PlayerStats`: if the
/// balance sat in the stats blob, every W-L-D update would rewrite the
/// ledger, and any unrelated bug in stats persistence could corrupt it.
class WalletRecord {
  const WalletRecord({
    this.balance = 0,
    this.journal = const [],
    this.applied = const [],
    this.bonusDebits = const {},
  });

  final int balance;

  /// Pending 100-coin bonus claims, keyed by recovery-wallet identity.
  final Map<String, String> bonusDebits;

  /// Banks debited locally, awaiting vault confirmation.
  final List<PendingBank> journal;

  /// Withdrawals already credited locally. Guards against double-credit
  /// when a withdrawal is replayed.
  final List<AppliedWithdrawal> applied;

  /// Cap on [applied]. Only *acked* entries are ever evicted — see [pruned].
  static const int appliedCap = 500;

  WalletRecord copyWith({
    int? balance,
    List<PendingBank>? journal,
    List<AppliedWithdrawal>? applied,
    Map<String, String>? bonusDebits,
  }) => WalletRecord(
    balance: balance ?? this.balance,
    journal: journal ?? this.journal,
    applied: applied ?? this.applied,
    bonusDebits: bonusDebits ?? this.bonusDebits,
  );

  /// Drops the oldest acked entries once [applied] exceeds [appliedCap],
  /// and never drops an unacked one however old it is.
  ///
  /// A bare list of ids cannot express that distinction. Evicting an entry
  /// whose ack never landed lets the recovery sweep credit those coins a
  /// second time, so age alone is the wrong eviction key — ack state is.
  WalletRecord get pruned {
    if (applied.length <= appliedCap) return this;
    var toDrop = applied.length - appliedCap;
    final kept = <AppliedWithdrawal>[];
    for (final entry in applied) {
      if (toDrop > 0 && entry.acked) {
        toDrop--;
        continue;
      }
      kept.add(entry);
    }
    return copyWith(applied: kept);
  }

  String encode() => jsonEncode({
    'v': 1,
    'balance': balance,
    'bonusDebits': bonusDebits,
    'journal': journal.map((e) => e.toJson()).toList(),
    'applied': applied.map((e) => e.toJson()).toList(),
  });

  /// Returns null when [raw] cannot be understood. Callers must fall back
  /// to the legacy integer balance rather than to an empty record —
  /// defaulting to zero on unreadable JSON silently wipes a real balance,
  /// and zero is exactly what an empty record looks like.
  static WalletRecord? decode(String raw) {
    try {
      final map = jsonDecode(raw);
      if (map is! Map) return null;
      final balance = map['balance'];
      if (balance is! int || balance < 0) return null;
      List<T> parse<T>(Object? list, T? Function(Object?) f) {
        if (list is! List) return <T>[];
        return list.map(f).whereType<T>().toList();
      }

      return WalletRecord(
        balance: balance,
        journal: parse(map['journal'], PendingBank.fromJson),
        applied: parse(map['applied'], AppliedWithdrawal.fromJson),
        bonusDebits: {
          if (map['bonusDebits'] is Map)
            for (final entry in (map['bonusDebits'] as Map).entries)
              if (entry.key is String && entry.value is String)
                entry.key as String: entry.value as String,
        },
      );
    } on FormatException {
      return null;
    }
  }
}
