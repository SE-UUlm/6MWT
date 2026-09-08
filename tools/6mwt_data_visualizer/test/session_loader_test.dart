import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:six_mwt_visualizer/core/data/session_loader.dart';

void main() {
  test('Loads all sessions from data directory', () async {
    const dataDir = '../../data';
    if (!Directory(dataDir).existsSync()) return;

    final data = await SessionLoader.loadFromDataDirectory(dataDir);
    expect(data.sessions.length, 10);

    // Basauri should not have a reference
    final basauri = data.sessions.firstWhere((s) => s.notes.contains('Basauri'));
    expect(basauri.hasReference, isFalse);
    expect(basauri.referenceSession, isNull);

    // Gasteiz 1 should have a reference
    final gasteiz = data.sessions.firstWhere((s) => s.notes.contains('Gasteiz 1'));
    expect(gasteiz.hasReference, isTrue);
    expect(gasteiz.referenceSession, isNotNull);
    expect(gasteiz.referenceSession!.distance, closeTo(598.3, 0.5));
  });

  test('Loads single session.json and automatically attaches reference.json', () async {
    const filePath = '../../data/Gräfenberg Wald 3/session.json';
    if (!File(filePath).existsSync()) return;

    final data = await SessionLoader.load(filePath);
    expect(data.sessions.length, 1);
    final session = data.sessions.first;
    expect(session.notes, contains('Gräfenberg Wald 3'));
    expect(session.hasReference, isTrue);
    expect(session.referenceSession, isNotNull);
    expect(session.referenceSession!.distance, closeTo(212.3, 0.5));
    expect(session.referenceSession!.positionSamples.length, 72);
  });

  test('Correctly trims reference recording to 6MWT session time window', () async {
    const filePath = '../../data/Gasteiz 2/session.json';
    if (!File(filePath).existsSync()) return;

    final data = await SessionLoader.load(filePath);
    final session = data.sessions.first;
    expect(session.hasReference, isTrue);

    // Untrimmed
    final rawRef = session.referenceSession!;
    expect(rawRef.distance, closeTo(720.0, 1.0));
    expect(rawRef.positionSamples.length, 92);

    // Trimmed to 360s window (+ 1 sample buffer before/after)
    final trimmedRef = session.trimmedReferenceSession;
    expect(trimmedRef, isNotNull);
    expect(trimmedRef!.distance, closeTo(626.9, 1.0));
    expect(trimmedRef.positionSamples.length, 75);
    expect(trimmedRef.duration, inInclusiveRange(355, 365));
  });
}
