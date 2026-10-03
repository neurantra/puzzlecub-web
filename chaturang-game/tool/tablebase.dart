import 'dart:io';
import 'dart:convert';
import 'package:chaturang/engine/tablebase.dart';

void main() {
  File(
    'build/web/tablebase.txt',
  ).writeAsStringSync(base64Encode(computeKrkTablebase()));
}
