import 'package:flutter/material.dart';

import '../engine/pieces.dart';
import 'appearance.dart';
import 'theme.dart';

/// The standard army, large enough to inspect its original Chaturang motifs.
class ArmyScreen extends StatefulWidget {
  const ArmyScreen({super.key});

  @override
  State<ArmyScreen> createState() => _ArmyScreenState();
}

class _ArmyScreenState extends State<ArmyScreen> {
  Side _side = Side.white;
  static const descriptions = {
    PieceType.king:
        'The royal throne. One square in any direction, with one knight-like leap per game.',
    PieceType.counsellor:
        'The counselor’s ceremonial insignia. Exactly one square diagonally.',
    PieceType.elephant:
        'An elephant beneath a royal howdah. Leaps two squares diagonally, over other pieces.',
    PieceType.knight:
        'The spirited horse. Two squares in one direction and one across, leaping over pieces.',
    PieceType.rook:
        'The wheeled royal chariot. Travels any distance along an unobstructed rank or file.',
    PieceType.pawn:
        'The shield-bearing foot soldier. Advances one square; captures one square diagonally forward.',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meet the army')),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Six identities. A different kind of strategy.',
            style: TextStyle(color: ChaturangTheme.secondaryText, fontSize: 14),
          ),
          const SizedBox(height: 16),
          SegmentedButton<Side>(
            segments: const [
              ButtonSegment(value: Side.white, label: Text('Ivory')),
              ButtonSegment(value: Side.black, label: Text('Ebony')),
            ],
            selected: {_side},
            onSelectionChanged: (values) =>
                setState(() => _side = values.single),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 600 ? 3 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .83,
                children: [
                  for (final type in PieceType.values)
                    Semantics(
                      button: true,
                      label: 'Inspect ${type.label}',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _inspect(type),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: const Color(0xFF223B3D),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFF62746C)),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    8,
                                    8,
                                    0,
                                  ),
                                  child: Image.asset(
                                    kSculptedPieces.sculptedAsset(type, _side)!,
                                    filterQuality: FilterQuality.medium,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Text(
                                type.sanskritName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: ChaturangTheme.primaryText,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                type.englishName,
                                style: const TextStyle(
                                  color: ChaturangTheme.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap a piece to explore its role. Both armies are included.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ChaturangTheme.secondaryText, fontSize: 12),
          ),
        ],
      ),
    ),
  );

  void _inspect(PieceType type) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              kSculptedPieces.sculptedAsset(type, _side)!,
              height: MediaQuery.sizeOf(context).height * .38,
              filterQuality: FilterQuality.medium,
            ),
            Text(
              type.label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ChaturangTheme.saffronLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              descriptions[type]!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to the army'),
            ),
          ],
        ),
      ),
    ),
  );
}
