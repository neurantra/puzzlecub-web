import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_the_jar/game/geometry.dart';
import 'package:fill_the_jar/ui/solid_scene.dart';

void main() {
  final data = jsonDecode(File('assets/levels.json').readAsStringSync());
  final puzzles = [
    ...(data['levels'] as List),
    ...(data['previews'] as List),
  ].map((j) => Puzzle.fromJson(Map<String, dynamic>.from(j))).toList();
  test(
    'rotation preserves model edge lengths and camera scale through a full turn',
    () {
      final p = puzzles[4], faces = jarMesh(p);
      final scale = SolidScenePainter(
        p,
        p.pieces,
        null,
        0,
        0,
      ).cameraScale(const Size(320, 400));
      for (final yaw in [0.0, .4, 1.57, 2.5, math.pi, math.pi * 2]) {
        for (final pitch in [-1.1, 0.0, 1.1]) {
          expect(
            SolidScenePainter(
              p,
              p.pieces,
              null,
              yaw,
              pitch,
            ).cameraScale(const Size(320, 400)),
            scale,
          );
          for (final f in faces) {
            for (var i = 0; i < f.points.length; i++) {
              final a = f.points[i], b = f.points[(i + 1) % f.points.length];
              expect(
                (a.rotated(yaw, pitch) - b.rotated(yaw, pitch)).length,
                closeTo((a - b).length, 1e-9),
              );
            }
          }
        }
      }
    },
  );
  test('every piece mesh stays inside its footprint and jar depth', () {
    for (final puzzle in puzzles) {
      for (final p in puzzle.pieces) {
        for (final f in pieceMesh(p)) {
          for (final v in f.points) {
            expect(v.x.isFinite && v.y.isFinite && v.z.isFinite, isTrue);
            expect(v.z.abs(), lessThanOrEqualTo(.320001));
            expect(v.x, inInclusiveRange(p.x - 1e-6, p.x + p.w + 1e-6));
            expect(v.y, inInclusiveRange(p.y - 1e-6, p.y + p.h + 1e-6));
          }
        }
      }
    }
  });
  test(
    'tray pieces use their available area instead of fixed large padding',
    () {
      final p = puzzles.first.pieces[1];
      final scale = SolidScenePainter(
        puzzles.first,
        [],
        p,
        -.22,
        .18,
        thumbnail: true,
      ).cameraScale(const Size(70, 50));
      expect(scale * p.h, greaterThan(40));
    },
  );
}
