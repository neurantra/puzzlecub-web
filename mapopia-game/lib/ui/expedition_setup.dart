import 'package:flutter/material.dart';
import '../game/expedition.dart';
import '../geo/domain/geo_region.dart';
import 'cartography.dart';
import 'destinations.dart';
import 'theme.dart';

class ExpeditionSetup extends StatefulWidget {
  const ExpeditionSetup({
    super.key,
    required this.region,
    required this.onStart,
    this.initialTrail = Trail.shapes,
    this.initialTimed = false,
    this.restarting = false,
  });
  final GeoRegion region;
  final void Function(Trail, bool) onStart;
  final Trail initialTrail;
  final bool initialTimed;
  final bool restarting;
  @override
  State<ExpeditionSetup> createState() => _ExpeditionSetupState();
}

class _ExpeditionSetupState extends State<ExpeditionSetup> {
  late Trail trail;
  late bool timed;
  @override
  void initState() {
    super.initState();
    trail = widget.initialTrail;
    timed = widget.initialTimed;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Your next destination'),
                    const SizedBox(height: 8),
                    Text(
                      geoRegionLabel(widget.region),
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      regionNotes[widget.region]!,
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 92,
                child: MapThumbnail(widget.region, height: 94),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Eyebrow('How will you explore?'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Trail.values
                .map(
                  (t) => ChoiceChip(
                    selected: trail == t,
                    showCheckmark: false,
                    selectedColor: teal,
                    label: Text(
                      t == Trail.names && !continents.contains(widget.region)
                          ? 'Names'
                          : t.label,
                      style: TextStyle(
                        color: trail == t ? Colors.white : ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onSelected: (_) => setState(() => trail = t),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Text(
            trail.description,
            style: const TextStyle(color: muted, fontSize: 12, height: 1.5),
          ),
          if (trail == Trail.clues)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Where a riddle is unavailable, you’ll see a capital clue.',
                style: TextStyle(color: muted, fontSize: 10),
              ),
            ),
          const SizedBox(height: 23),
          const Eyebrow('Set your pace'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _pace(
                  false,
                  Icons.spa_outlined,
                  'Relaxed',
                  'No rush. Just discovery.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _pace(
                  true,
                  Icons.timer_outlined,
                  'Timed',
                  'A little extra adventure.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.restarting)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Starting a new expedition resets this map’s pieces, time, and score. Your other maps and journal stay saved.',
                style: TextStyle(fontSize: 12, height: 1.5, color: muted),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onStart(trail, timed),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.restarting
                        ? 'Start new expedition'
                        : 'Begin expedition',
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'All maps included · Saved in this browser',
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ),
        ],
      ),
    ),
  );
  Widget _pace(
    bool value,
    IconData icon,
    String title,
    String subtitle,
  ) => Material(
    color: timed == value ? const Color(0xFFE1EADD) : const Color(0xFFF1EEE4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: timed == value ? teal : line),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => timed = value),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: teal, size: 22),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: muted)),
          ],
        ),
      ),
    ),
  );
}
