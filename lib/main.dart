import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';

import 'data.dart';

@JS('playUke')
external JSPromise<JSBoolean> playUke(JSString key, JSBoolean slow);
@JS('stopUke')
external void stopUke();
@JS('labUke')
external void labUke(JSString steps, JSNumber bpm, JSBoolean slow);
void main() => runApp(const GrooveApp());

class GrooveApp extends StatelessWidget {
  const GrooveApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Ukulele Groove',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff197c69)),
      scaffoldBackgroundColor: const Color(0xfff6f4ec),
      fontFamily: 'sans-serif',
    ),
    home: const Practice(),
  );
}

class Practice extends StatefulWidget {
  const Practice({super.key});
  @override
  State<Practice> createState() => _PracticeState();
}

class _PracticeState extends State<Practice> {
  int index = 0;
  String selected = '', playing = '', error = '';
  bool checked = false,
      heard = false,
      slow = false,
      hint = false,
      learn = false,
      lab = false;
  List<String> custom = [];
  final Set<int> explored = {};
  Map<String, Object> get lesson => lessons[index];
  Map<String, Object> pattern(String id) =>
      patterns.firstWhere((p) => p['id'] == id);
  Map<String, Object> get best => pattern(lesson['best'] as String);
  void stop() {
    stopUke();
    setState(() => playing = '');
  }

  Future<void> play(String mode) async {
    stop();
    setState(() => error = '');
    final ok = (await playUke('${lesson['id']}-$mode'.toJS, slow.toJS).toDart).toDart;
    if (!mounted) return;
    setState(() {
      playing = ok ? mode : '';
      if (ok && (mode == 'song' || mode == 'guide')) heard = true;
      if (!ok) error = 'Audio could not start. Tap play again and check your device volume.';
    });
  }

  void next() {
    stop();
    setState(() {
      index = (index + 1) % lessons.length;
      selected = '';
      checked = false;
      heard = false;
      hint = false;
      learn = false;
      lab = false;
    });
  }

  Widget text(String t, {bool bold = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      t,
      style: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
      ),
    ),
  );
  Widget button(String t, VoidCallback? f, {bool primary = false}) => primary
      ? FilledButton(onPressed: f, child: Text(t))
      : OutlinedButton(onPressed: f, child: Text(t));
  Widget row(List<Widget> widgets) =>
      Wrap(spacing: 10, runSpacing: 10, children: widgets);
  Widget section(String title, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xffe3e5db)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [text(title, bold: true), ...children],
    ),
  );
  static const marks = {'D': '↓', 'U': '↑', '-': '·', 'X': '×'};
  Widget grid(List<String> slots, {bool editable = false}) => LayoutBuilder(
    builder: (context, c) {
      return Wrap(
        spacing: 4,
        runSpacing: 8,
        children: List.generate(slots.length, (i) {
          final s = slots[i];
          return SizedBox(
            width: (c.maxWidth - 12) / 4,
            child: Column(
              children: [
                Text(
                  i.isEven ? '${i ~/ 2 + 1}' : '&',
                  style: const TextStyle(color: Colors.grey),
                ),
                editable
                    ? OutlinedButton(
                        onPressed: () {
                          stop();
                          setState(() {
                            final cycle = i.isEven
                                ? ['D', 'X', '-']
                                : ['U', 'X', '-'];
                            custom[i] = cycle[(cycle.indexOf(s) + 1) % 3];
                          });
                        },
                        child: Text(
                          marks[s]!,
                          style: const TextStyle(fontSize: 28),
                        ),
                      )
                    : Text(
                        marks[s]!,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                Text(
                  s == '-'
                      ? 'skip'
                      : s == 'X'
                      ? 'mute'
                      : s == 'D'
                      ? 'down'
                      : 'up',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        }),
      );
    },
  );
  @override
  Widget build(BuildContext context) {
    final picked = selected.isEmpty ? null : pattern(selected);
    final same = picked?['meter'] == lesson['meter'];
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'UKULELE GROOVE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: Color(0xff197c69),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Find your groove.',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  text('Listen. Try a strum. Learn why it fits.'),
                  text(
                    'Lesson ${index + 1} / ${lessons.length}  •  ${explored.length} explored',
                  ),
                  section(lesson['name'] as String, [
                    text(
                      checked
                          ? '${lesson['meter']}/4 time • ${lesson['bpm']} BPM'
                          : 'Feel where the strong beat comes back.',
                    ),
                    row([
                      button(
                        playing.isEmpty
                            ? (heard ? 'Replay song' : '▶ Play song')
                            : 'Stop audio',
                        () => playing.isEmpty ? play('song') : stop(),
                        primary: true,
                      ),
                      button(slow ? '0.75× slow' : 'Slow it down', () {
                        stop();
                        setState(() => slow = !slow);
                      }),
                    ]),
                  ]),
                  if (error.isNotEmpty) text(error),
                  if (!checked)
                    section('Which strum would you try?', [
                      text('↓ down  ·  ↑ up  ·  · skip  ·  × muted hit'),
                      ...((lesson['options'] as List).map((id) {
                        final p = pattern(id as String);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: selected == id
                                ? const Color(0xffdff3eb)
                                : const Color(0xfff6f7f2),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() => selected = id),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${p['name']}   ${p['meter']} beats',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (p['steps'] as List)
                                          .map((s) => marks[s])
                                          .join('  '),
                                      style: const TextStyle(fontSize: 25),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      })),
                      row([
                        button(
                          'Check my choice',
                          selected.isEmpty || !heard
                              ? null
                              : () {
                                  stop();
                                  setState(() {
                                    checked = true;
                                    explored.add(index);
                                    custom = List<String>.from(
                                      best['steps'] as List,
                                    );
                                  });
                                },
                          primary: true,
                        ),
                        button(
                          hint ? 'Hide hint' : 'Need a hint?',
                          () => setState(() => hint = !hint),
                        ),
                      ]),
                      if (!heard) text('Listen once to unlock the check.'),
                      if (hint) ...[
                        const SizedBox(height: 12),
                        text(
                          'Tap to the bass. Count until its strong note comes back. Listen for notes between those beats.',
                        ),
                        button('Hear beat guide', () => play('guide')),
                      ],
                    ]),
                  if (checked) ...[
                    section(
                      selected == best['id']
                          ? 'That fits the feel.'
                          : same
                          ? 'That can work, too.'
                          : 'Try a different beat cycle.',
                      [
                        text(
                          selected == best['id']
                              ? lesson['why'] as String
                              : same
                              ? 'Your ${lesson['meter']}-beat choice is a valid arrangement. ${lesson['why']}'
                              : 'Your ${picked?['meter']}-beat pattern resets on a different cycle from this ${lesson['meter']}-beat song. Count the bass returning on 1 and compare.',
                        ),
                        row([
                          button('Hear my choice', () => play(selected)),
                          button(
                            'Hear suggested fit',
                            () => play(lesson['best'] as String),
                            primary: true,
                          ),
                        ]),
                        const SizedBox(height: 18),
                        text('Suggested: ${best['name']}', bold: true),
                        grid(List<String>.from(best['steps'] as List)),
                      ],
                    ),
                    section('Why the gaps matter', [
                      text(lesson['rest'] as String),
                      text('Skip is not mute', bold: true),
                      text(
                        'A dot: move past the strings without touching. ×: a short muted sound. Keep your hand moving through both.',
                      ),
                      button(
                        learn
                            ? 'Hide listening steps'
                            : 'How do I find a pattern?',
                        () => setState(() => learn = !learn),
                      ),
                      if (learn) ...[
                        const SizedBox(height: 14),
                        text(
                          '1. Find the pulse. Tap to the bass, not every melody note.',
                        ),
                        button('Hear beat guide', () => play('guide')),
                        text(
                          '2. Find the reset. Count the ${lesson['meter']} beats between recurring strong accents.',
                        ),
                        text('3. Listen between beats. ${lesson['hear']}'),
                        text(
                          '4. Try, then simplify. Move down on numbers, up on “ands”. Skip strokes when a busy strum crowds the melody. There is no compulsory pattern.',
                        ),
                      ],
                    ]),
                    section('Make room in the rhythm', [
                      button(
                        lab ? 'Close rhythm lab' : 'Open rhythm lab',
                        () => setState(() => lab = !lab),
                      ),
                      if (lab) ...[
                        const SizedBox(height: 14),
                        text(
                          'Tap a slot: stroke → mute → skip. Four bars of a C chord.',
                        ),
                        grid(custom, editable: true),
                        const SizedBox(height: 16),
                        row([
                          button('Play my rhythm', () {
                            stop();
                            labUke(
                              jsonEncode(custom).toJS,
                              (lesson['bpm'] as int).toJS,
                              slow.toJS,
                            );
                            setState(() => playing = 'custom');
                          }, primary: true),
                          button('Reset', () {
                            stop();
                            setState(
                              () => custom = List<String>.from(
                                best['steps'] as List,
                              ),
                            );
                          }),
                          button('Stop', stop),
                        ]),
                      ],
                    ]),
                    row([
                      button(
                        index == lessons.length - 1
                            ? 'Practice again'
                            : 'Next mini-song →',
                        next,
                        primary: true,
                      ),
                      button('Try another answer', () {
                        stop();
                        setState(() => checked = false);
                      }),
                    ]),
                    const SizedBox(height: 24),
                  ],
                  ExpansionTile(
                    title: const Text('Pattern guide & practice notes'),
                    children: [
                      text(
                        'Original synthesized mini-songs, not commercial recordings. Suggested means one arrangement, not the only answer. No microphone scoring. Progress lasts for this open session.',
                      ),
                      ...patterns.map(
                        (p) => section(p['name'] as String, [
                          grid(List<String>.from(p['steps'] as List)),
                          const SizedBox(height: 12),
                          text(p['tip'] as String),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  text(
                    'Start with low volume. Keep your hand moving, even when you skip the strings.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
