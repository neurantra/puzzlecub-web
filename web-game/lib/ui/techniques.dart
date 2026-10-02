import 'package:flutter/material.dart';
import 'style.dart';

/// Original letter-based explanations. Available without a network connection.
class TechniqueReference {
  const TechniqueReference(this.name, this.alias, this.rule, this.example);
  final String name, alias, rule, example;
}

const techniqueReference = [
  TechniqueReference(
    'Scanning',
    'Start here',
    'Choose one letter. Inspect its existing placements to rule out empty cells in the same row, column and box. Look for a forced position.',
    'An A elsewhere in a column prevents another A in that column. Use several such exclusions to narrow down the A in a box.',
  ),
  TechniqueReference(
    'One Choice',
    'Naked single',
    'An empty cell has exactly one legal candidate after checking its row, column and box. Place that letter.',
    'If a cell cannot contain any target letter except M, it must be M.',
  ),
  TechniqueReference(
    'Hidden Single',
    'One location',
    'Within one unit, a letter is possible in exactly one cell. That cell must contain it, even when other letters are also pencilled there.',
    'Only one cell in row 4 allows A. That cell is A, even if its notes also show B and C.',
  ),
  TechniqueReference(
    'Naked Pair',
    'Two cells, two letters',
    'Two cells in the same unit each have exactly the same two candidates. Those letters must occupy those cells, in some order. Eliminate them from the other cells of that unit.',
    'Two cells in a row have {A,B} and {A,B}. Remove A and B from every other cell in that row.',
  ),
  TechniqueReference(
    'Hidden Pair',
    'Two letters, two locations',
    'In one unit, two letters are possible only in the same two cells. Keep those letters in those cells and remove their other candidates.',
    'A and B occur as candidates only in cells X and Y. Notes {A,B,C} and {A,B,D} become {A,B} and {A,B}.',
  ),
  TechniqueReference(
    'Interaction',
    'Locked candidates',
    'Pointing: all positions for a letter in a box lie in one row or column, so exclude it from the rest of that line. Claiming: all positions in a line lie in one box, so exclude it from the rest of that box.',
    'All possible As in the top-left box lie in row 2. Remove A from row 2 outside that box.',
  ),
  TechniqueReference(
    'Naked Triple',
    'Three cells, three letters',
    'Three unsolved cells in one unit have only three different candidates between them. Each cell may have two or three of them. Remove these letters from all other cells in the unit.',
    '{A,B}, {B,C}, {A,C} reserve A, B and C for those three cells.',
  ),
  TechniqueReference(
    'Hidden Triple',
    'Three letters, three locations',
    'Three letters are confined to three cells of a unit. Remove all other candidates from those cells. Every letter need not occur in every one of the three cells.',
    'If only X, Y and Z can hold A, B or C in a box, erase D and E from their notes.',
  ),
  TechniqueReference(
    'Naked Quad',
    'Four cells, four letters',
    'Four unsolved cells in one unit collectively allow only four letters. Eliminate those four letters from every other cell in that unit.',
    '{A,B}, {B,C}, {C,D}, {A,D} reserve A, B, C and D for these four cells.',
  ),
  TechniqueReference(
    'X-Wing',
    'A rectangle for one letter',
    'Find two rows in which a particular letter has exactly two possible columns, the same two in both rows. Eliminate that letter from those columns in other rows. The rule also works with rows and columns swapped.',
    'A is possible only in columns 2 and 7 of rows 1 and 6. Remove A from columns 2 and 7 outside rows 1 and 6.',
  ),
  TechniqueReference(
    'Y-Wing',
    'Also called XY-Wing',
    'A pivot {A,B} sees two wings {A,C} and {B,C}. Each cell has exactly two candidates. Whichever pivot letter is chosen, one wing is C. Remove C from other cells that see both wings.',
    'The pivot need not share one unit with both wings: one can share its row and the other its box. Only cells seeing BOTH wings lose C.',
  ),
  TechniqueReference(
    'XY-Chain',
    'Linked two-candidate cells',
    'Follow cells that each have exactly two candidates, with successive cells seeing one another. Each forced second candidate links to the next cell. If the endpoints share a letter and excluding it at one end forces it at the other, remove it from cells seeing both ends.',
    'A valid chain {A,B} → {B,C} → {C,D} → {D,A} means at least one endpoint is A. Other cells seeing both endpoints cannot be A.',
  ),
];

Future<void> showTechniques(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const TechniquesScreen()));

class TechniquesScreen extends StatefulWidget {
  const TechniquesScreen({super.key});
  @override
  State<TechniquesScreen> createState() => _TechniquesScreenState();
}

class _TechniquesScreenState extends State<TechniquesScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final matches = techniqueReference.where(
      (t) => '${t.name} ${t.alias}'.toLowerCase().contains(query.toLowerCase()),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Solving techniques')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'A candidate is a letter that could legally occupy a cell. A unit is a row, column or 3×3 box. Two cells “see” one another when they share a unit. Examples use placeholder letters; use your puzzle’s nine letters.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Keep notes complete before making eliminations. These are reference patterns, not automatic hints or guarantees about a puzzle’s difficulty.',
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Find a technique',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => query = value),
                ),
                const SizedBox(height: 12),
                if (matches.isEmpty)
                  const Text(
                    'No matching techniques. Try “pair”, “wing” or “single”.',
                  ),
                for (final technique in matches)
                  Card(
                    child: ExpansionTile(
                      key: ValueKey(technique.name),
                      title: Text(
                        technique.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(technique.alias),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text(technique.rule),
                        const SizedBox(height: 12),
                        Text(
                          'Example',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(technique.example),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                const Surface(
                  child: Text(
                    'The Alphadoku twist: compare each possible hidden line with the target’s letter order. A conflicting fixed letter rules that line out. Standard Sudoku deductions and hidden-line deductions work together.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
