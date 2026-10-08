import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'data.dart';

@JS('loadSongLibrary')
external JSString loadSongLibrary();
@JS('saveSongLibrary')
external JSBoolean saveSongLibrary(JSString value);
@JS('analyzeYouTubeUke')
external JSPromise<JSString> analyzeYouTubeUke(JSString id);
@JS('getUkeQuota')
external JSPromise<JSString> getUkeQuota();
@JS('labUke')
external void playSongPattern(JSString steps, JSNumber bpm, JSBoolean slow);
@JS('makeYouTubeFrame')
external JSObject makeYouTubeFrame(JSString id);

String? youtubeId(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null || !['https', 'http'].contains(uri.scheme)) return null;
  final host = uri.host.toLowerCase();
  String? id;
  if (host == 'youtu.be' || host == 'www.youtu.be') {
    id = uri.pathSegments.firstOrNull;
  } else if ([
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
  ].contains(host)) {
    id = uri.path == '/watch'
        ? uri.queryParameters['v']
        : (uri.pathSegments.length > 1 &&
                  ['embed', 'shorts', 'live'].contains(uri.pathSegments.first)
              ? uri.pathSegments[1]
              : null);
  }
  return id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id) ? id : null;
}

class SongLibrary extends StatefulWidget {
  const SongLibrary({super.key});
  @override
  State<SongLibrary> createState() => _SongLibraryState();
}

class _SongLibraryState extends State<SongLibrary> {
  final link = TextEditingController(), title = TextEditingController();
  List<Map<String, dynamic>> songs = [];
  String notice = '', feel = 'Steady';
  int meter = 4, bpm = 90, serial = 0;
  Map<String, dynamic>? active;
  String? viewType;
  bool analyzing = false;
  String quotaNote = 'Checking free converter capacity...';
  Future<void> refreshQuota() async {
    try {
      final q = jsonDecode((await getUkeQuota().toDart).toDart) as Map;
      if (!mounted) {
        return;
      }
      final cloud = q['cloudflare'] as Map?;
      final seconds = (cloud?['usedBrowserTimeSeconds'] as num?)?.toDouble();
      setState(
        () => quotaNote = seconds == null
            ? 'Free capacity unavailable. Conversions may be limited; no paid upgrade.'
            : 'Shared free browser budget: ${(seconds / 60).toStringAsFixed(1)} / 10 minutes used today. Converter capacity is separate. When all free capacity is exhausted, new analysis stops; saved songs still work.',
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => quotaNote = 'Capacity check unavailable; no paid upgrade.',
        );
      }
    }
  }

  Future<void> analyzeAudio() async {
    if (analyzing || active == null) return;
    final song = active!;
    setState(() {
      analyzing = true;
      notice = 'Getting converter audio, then analyzing on this device. This can take a minute...';
    });
    try {
      final raw = (await analyzeYouTubeUke(
        youtubeId(song['url'] as String)!.toJS,
      ).toDart).toDart;
      if (raw.isNotEmpty && mounted) {
        final result = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        setState(() {
          song['analysis'] = result;
          song['bpm'] = result['bpm'];
          song['meter'] = result['meter'];
          song['suggested'] = result['best'];
          notice = saveSongLibrary(jsonEncode(songs).toJS).toDart
              ? 'Audio analysis saved in this browser.'
              : 'Analysis ready for this session; browser storage unavailable.';
        });
      }
    } catch (e) {
      setState(() => notice = 'Audio analysis failed: $e');
    }
    if (mounted) setState(() => analyzing = false);
    refreshQuota();
  }

  Map<String, Object> songPattern(String id) {
    final base = patterns.firstWhere((p) => p['id'] == id);
    if (active?['meter'] != 3 || id == 'waltz') return base;
    final threeBeat = <String, List<String>>{
      'eighths': ['D', 'U', 'D', 'U', 'D', 'U'],
      'island': ['D', '-', 'D', 'U', '-', 'U'],
      'chuck': ['D', '-', 'X', 'U', 'D', 'U'],
      'steady': ['D', '-', 'D', '-', 'D', '-'],
    };
    return {...base, 'steps': threeBeat[id]!, 'beats': 3};
  }

  void demo(String id) {
    final p = songPattern(id);
    playSongPattern(
      jsonEncode(p['steps']).toJS,
      (active!['bpm'] as num).toDouble().toJS,
      false.toJS,
    );
  }

  bool _closeScores(Map scores) {
    final sorted =
        scores.values.whereType<num>().map((v) => v.toDouble()).toList()
          ..sort((a, b) => b.compareTo(a));
    return sorted.length > 1 && sorted[0] - sorted[1] < 0.02;
  }

  Widget exercise() {
    final result = active!['analysis'] as Map?;
    if (result == null) return const SizedBox.shrink();
    final options = active!['meter'] == 3
        ? ['waltz', 'eighths', 'island', 'chuck']
        : ['steady', 'eighths', 'island', 'chuck'];
    final chosen = active!['selected'] as String;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          'Which strum would you try?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          'Audio estimate: ${active!['bpm']} BPM · ${active!['meter']}/4. Meter may need a listening check.',
        ),
        Text(
          'Beat detection confidence: ${((result['confidence'] as num) * 100).round()}% (relative strength, not an accuracy probability). This score applies to tempo, not meter or strum choice.',
        ),
        if (active!['meter'] != 3 &&
            (result['scores'] as Map?) != null &&
            _closeScores(result['scores'] as Map))
          const Text(
            'Near-tie: several strums fit this audio similarly. Try different options and choose what sounds better.',
          ),
        const Text(
          'A suggested starting arrangement, not one correct answer or a detected original strum.',
        ),
        RadioGroup<String>(
          groupValue: chosen,
          onChanged: (value) {
            setState(() {
              active!['selected'] = value;
              saveSongLibrary(jsonEncode(songs).toJS);
            });
          },
          child: Column(
            children: options.map((id) {
              final p = songPattern(id);
              return RadioListTile<String>(
                value: id,
                title: Text(p['name'] as String),
                subtitle: Text((p['steps'] as List).join(' ')),
              );
            }).toList(),
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: chosen.isEmpty ? null : () => demo(chosen),
              child: const Text('Hear my choice'),
            ),
            OutlinedButton(
              onPressed: () => demo(active!['suggested'] as String),
              child: const Text('Hear suggested choice'),
            ),
          ],
        ),
        Text(
          'Suggested: ${songPattern(active!['suggested'] as String)['name']}',
        ),
        const Text(
          'Demos are a synthesized C chord at the estimated tempo. They do not recreate song chords or synchronize with the video.',
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    refreshQuota();
    try {
      final saved = jsonDecode(loadSongLibrary().toDart);
      if (saved is List) {
        songs = saved
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => youtubeId(e['url']?.toString() ?? '') != null)
            .toList();
      }
    } catch (_) {
      notice =
          'Saved library could not be loaded. Your browser may block storage.';
    }
  }

  @override
  void dispose() {
    link.dispose();
    title.dispose();
    super.dispose();
  }

  void open(Map<String, dynamic> song) {
    final id = youtubeId(song['url'] as String)!;
    final type = 'youtube-song-${serial++}';
    ui_web.platformViewRegistry.registerViewFactory(
      type,
      (_) => makeYouTubeFrame(id.toJS),
    );
    setState(() {
      active = song;
      viewType = type;
    });
  }

  void add() {
    final id = youtubeId(link.text);
    if (id == null) {
      setState(
        () => notice = 'Paste a valid YouTube video link (watch, youtu.be, Shorts or live).',
      );
      return;
    }
    final existing = songs
        .where((s) => youtubeId(s['url'] as String) == id)
        .firstOrNull;
    if (existing != null) {
      open(existing);
      if (existing['analysis'] == null) analyzeAudio();
      setState(() => notice = 'This song is already in your library.');
      return;
    }
    final song = <String, dynamic>{
      'url': link.text.trim(),
      'title': title.text.trim().isEmpty
          ? 'YouTube song $id'
          : title.text.trim(),
      'bpm': bpm,
      'meter': meter,
      'feel': feel,
      'selected': '',
      'suggested': '',
    };
    songs.insert(0, song);
    final ok = saveSongLibrary(jsonEncode(songs).toJS).toDart;
    open(song);
    setState(
      () => notice = ok
          ? 'Saved in this browser.'
          : 'Added for this session only: browser storage is unavailable.',
    );
    analyzeAudio();
  }

  Widget panel(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final input = panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add your own song',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(quotaNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              controller: link,
              decoration: const InputDecoration(
                labelText: 'YouTube song link',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Song title (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Paste a song link. Audio analysis will estimate tempo, meter and a starting strum, with uncertainty shown.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: analyzing ? null : add,
              child: const Text('Add song & analyze'),
            ),
            if (notice.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(notice),
              ),
            if (active != null) ...[
              const SizedBox(height: 20),
              Text(
                active!['title'] as String,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                'Play song using the YouTube controls below. Some videos cannot be embedded; use the original link if YouTube reports an error.',
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: HtmlElementView(viewType: viewType!),
              ),
              const SizedBox(height: 12),
              SelectableText(active!['url'] as String),
              FilledButton(
                onPressed: analyzing ? null : analyzeAudio,
                child: Text(analyzing ? 'Analyzing audio...' : 'Analyze again'),
              ),
              exercise(),
            ],
          ],
        ),
      );
      final library = panel(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your added songs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Saved on this device in this browser only. Clearing site storage removes the library. No account sync.',
            ),
            if (songs.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text('No songs added yet.'),
              ),
            ...songs.map(
              (s) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s['title'] as String),
                subtitle: Text(
                  s['analysis'] == null
                      ? 'Not analyzed yet'
                      : '${s['meter']}/4 · ${s['bpm']} BPM\nPattern: ${s['selected'] == '' ? 'Not chosen yet' : songPattern(s['selected'] as String)['name']}',
                ),
                onTap: analyzing ? null : () => open(s),
              ),
            ),
          ],
        ),
      );
      if (size.maxWidth >= 960) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: input),
            const SizedBox(width: 18),
            Expanded(child: library),
          ],
        );
      }
      return Column(children: [input, const SizedBox(height: 18), library]);
    },
  );
}
