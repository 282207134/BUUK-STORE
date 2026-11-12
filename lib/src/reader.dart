import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'store_state.dart';
import 'ui.dart';

void openReader(BuildContext context, Book book) {
  StoreScope.of(context).read(book);
  pushPage(context, ReaderPage(book));
}

Future<void> showAudioPreview(BuildContext context, Book book) =>
    showPanel<void>(context, _AudioPanel(book), shade: .59);

class ReaderPage extends StatefulWidget {
  const ReaderPage(this.book, {super.key});

  final Book book;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  static const totalPages = 352;
  String search = '';

  Future<void> find() async {
    final query = await showPanel<String>(
      context,
      const Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 18),
        child: _FindInBook(),
      ),
    );
    if (query != null && mounted) setState(() => search = query.trim());
  }

  Future<void> contents(StoreState store) async {
    final page = await showPanel<int>(
      context,
      Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: SectionTitle('Contents', subtitle: null),
          ),
          for (final chapter in [(1, 1), (2, 118), (3, 236)])
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text('Chapter ${chapter.$1}'),
              trailing: Text('${chapter.$2}'),
              onTap: () => Navigator.pop(context, chapter.$2),
            ),
        ],
      ),
    );
    if (page != null && mounted) store.updatePage(widget.book, page);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final book = widget.book;
    final (chrome, paper, ink, controls) = _readingColors(store.readingTheme);
    final page = store.pageOf(book);
    final bookmark = store.bookmarks.contains(book);
    final adjustedPaper = Color.lerp(
      Colors.black,
      paper,
      .8 + .2 * store.pageBrightness,
    )!;
    return PageFrame(
      color: chrome,
      lightStatus: controls == Colors.white,
      body: Column(
        children: [
          IconTheme(
            data: IconThemeData(color: controls, size: 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ReaderTool(
                  'Minimize reader',
                  Icons.keyboard_arrow_down,
                  () => Navigator.pop(context),
                ),
                _ReaderTool(
                  'Contents',
                  Icons.format_list_bulleted,
                  () => contents(store),
                ),
                _ReaderTool(
                  'Audio preview',
                  Icons.music_note_outlined,
                  () => showAudioPreview(context, book),
                ),
                const Spacer(),
                _ReaderTool('Find in book', Icons.search, find),
                _ReaderTool(
                  'Reading settings',
                  Icons.text_fields,
                  () => showPanel<void>(
                    context,
                    const _ReadingSettings(),
                    shade: .64,
                  ),
                ),
                _ReaderTool('Copy excerpt', Icons.ios_share, () async {
                  await Clipboard.setData(
                    const ClipboardData(text: readerExcerpt),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Excerpt copied')),
                    );
                  }
                }),
                _ReaderTool(
                  'Bookmark',
                  bookmark ? Icons.bookmark : Icons.bookmark_border,
                  () => store.toggleBookmark(book),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Material(
              color: adjustedPaper,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  child: Text.rich(
                    TextSpan(children: _highlights(readerExcerpt, search)),
                    style: TextStyle(
                      color: ink,
                      fontSize: store.readingFontSize,
                      height: 1.75,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Icon(Icons.outlined_flag, color: controls, size: 21),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            '$page of $totalPages  ·  (${(page / totalPages * 100).round()}%)',
                            style: TextStyle(color: controls, fontSize: 12),
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 4,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            min: 1,
                            max: totalPages.toDouble(),
                            value: page.toDouble(),
                            activeColor: controls,
                            inactiveColor: controls.withValues(alpha: .28),
                            semanticFormatterCallback: (value) =>
                                'Page ${value.round()}',
                            onChanged: (value) =>
                                store.updatePage(book, value.round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderTool extends StatelessWidget {
  const _ReaderTool(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: label,
    onPressed: onTap,
    icon: Icon(icon),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 44, height: 48),
  );
}

class _FindInBook extends StatefulWidget {
  const _FindInBook();

  @override
  State<_FindInBook> createState() => _FindInBookState();
}

class _FindInBookState extends State<_FindInBook> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Column(
      children: [
        const SectionTitle('Find in book', subtitle: null),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => Navigator.pop(context, value),
          decoration: const InputDecoration(
            hintText: 'Find text in the excerpt',
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton('Find', () => Navigator.pop(context, controller.text)),
      ],
    ),
  );
}

List<TextSpan> _highlights(String text, String query) {
  if (query.isEmpty) return [TextSpan(text: text)];
  final matches = RegExp(
    RegExp.escape(query),
    caseSensitive: false,
  ).allMatches(text);
  var cursor = 0;
  return [
    for (final match in matches) ...[
      TextSpan(text: text.substring(cursor, match.start)),
      TextSpan(
        text: text.substring(match.start, cursor = match.end),
        style: const TextStyle(backgroundColor: Color(0xffffd694)),
      ),
    ],
    TextSpan(text: text.substring(cursor)),
  ];
}

(Color, Color, Color, Color) _readingColors(
  ReadingTheme theme,
) => switch (theme) {
  ReadingTheme.light => (Palette.paper, Colors.white, Palette.ink, Palette.ink),
  ReadingTheme.sepia => (
    const Color(0xfff4e9d5),
    const Color(0xfffff6e7),
    const Color(0xff59462e),
    const Color(0xff59462e),
  ),
  ReadingTheme.dark => (Palette.ink, Colors.white, Palette.ink, Colors.white),
  ReadingTheme.darkest => (
    const Color(0xff22252a),
    const Color(0xff30333a),
    Colors.white,
    Colors.white,
  ),
};

class _ReadingSettings extends StatelessWidget {
  const _ReadingSettings();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    const labels = ['Light', 'Sepia', 'Dark', 'Darkest'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          const SectionTitle('Reading settings', subtitle: null),
          const SizedBox(height: 13),
          _PreferenceSlider(
            label: 'Page brightness',
            start: const Icon(Icons.light_mode_outlined, size: 16),
            end: const Icon(Icons.light_mode, size: 20),
            value: store.pageBrightness,
            onChanged: (value) =>
                store.setReadingPreferences(brightness: value),
          ),
          _PreferenceSlider(
            label: 'Text size',
            start: const Text('T', style: TextStyle(fontSize: 12)),
            end: const Text('T', style: TextStyle(fontSize: 20)),
            value: (store.readingFontSize - 12) / 8,
            onChanged: (value) =>
                store.setReadingPreferences(fontSize: 12 + value * 8),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final theme in ReadingTheme.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OutlinedButton(
                      onPressed: () =>
                          store.setReadingPreferences(theme: theme),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: _readingColors(theme).$1,
                        foregroundColor: _readingColors(theme).$4,
                        side: BorderSide(
                          color: store.readingTheme == theme
                              ? Palette.blue
                              : Palette.mist,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(0, 48),
                      ),
                      child: Text(
                        labels[theme.index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferenceSlider extends StatelessWidget {
  const _PreferenceSlider({
    required this.label,
    required this.start,
    required this.end,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Widget start;
  final Widget end;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => IconTheme(
    data: const IconThemeData(color: Palette.muted),
    child: Row(
      children: [
        start,
        Expanded(
          child: Semantics(
            label: label,
            child: Slider(
              activeColor: Palette.blue,
              inactiveColor: Palette.mist,
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
        end,
      ],
    ),
  );
}

class _AudioPanel extends StatefulWidget {
  const _AudioPanel(this.book);

  final Book book;

  @override
  State<_AudioPanel> createState() => _AudioPanelState();
}

class _AudioPanelState extends State<_AudioPanel> {
  static const channel = MethodChannel('buuk_store/preview');
  static const speeds = [1.0, 1.25, 1.5, 0.75];
  int part = 0;
  int speed = 0;
  bool playing = false;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    channel.setMethodCallHandler((call) async {
      if (!mounted || call.method != 'complete') return;
      if (part + 1 < audioExcerpt.length) {
        await selectPart(part + 1, autoplay: true);
      } else {
        setState(() => playing = false);
      }
    });
  }

  @override
  void dispose() {
    channel.setMethodCallHandler(null);
    unawaited(channel.invokeMethod<void>('stop').catchError((Object _) {}));
    super.dispose();
  }

  Future<void> control(
    String method,
    VoidCallback update, {
    Object? arguments,
  }) async {
    if (busy) return;
    setState(() {
      error = null;
      busy = true;
    });
    try {
      await channel.invokeMethod<void>(method, arguments);
      if (mounted) setState(update);
    } on PlatformException {
      if (mounted) setState(() => error = 'Could not play the audio sample.');
    } on MissingPluginException {
      if (mounted) {
        setState(() => error = 'Audio preview is available on mobile.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> play() => control(
    playing ? 'pause' : 'play',
    () => playing = !playing,
    arguments: {'part': part, 'rate': speeds[speed]},
  );

  Future<void> selectPart(int index, {required bool autoplay}) =>
      control(autoplay ? 'play' : 'stop', () {
        part = index;
        playing = autoplay;
      }, arguments: {'part': index, 'rate': speeds[speed]});

  Future<void> changeSpeed() {
    final next = (speed + 1) % speeds.length;
    return control('rate', () => speed = next, arguments: speeds[next]);
  }

  @override
  Widget build(BuildContext context) {
    final rate = speeds[speed];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 15),
      child: Column(
        children: [
          const Text(
            'CHAPTER 1',
            style: TextStyle(fontSize: 13, color: Palette.muted),
          ),
          const SizedBox(height: 4),
          Text(
            widget.book == featuredBook
                ? 'Saving The Sun Dragon'
                : 'BUUK audio sample',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 22),
          for (var index = 0; index < audioExcerpt.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text.rich(
                TextSpan(
                  children: [
                    if (index == part)
                      TextSpan(
                        text: audioExcerpt[index].substring(
                          0,
                          audioExcerpt[index].indexOf(' to ') + 1,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          backgroundColor: Palette.blue,
                        ),
                      ),
                    TextSpan(
                      text: index == part
                          ? audioExcerpt[index].substring(
                              audioExcerpt[index].indexOf(' to ') + 1,
                            )
                          : audioExcerpt[index],
                    ),
                  ],
                ),
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 14, height: 1.65),
              ),
            ),
          if (error case final message?)
            Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: busy ? null : changeSpeed,
                child: Text('${rate == 1 ? '1' : rate}x'),
              ),
              IconButton(
                tooltip: 'Previous passage',
                onPressed: part == 0 || busy
                    ? null
                    : () => selectPart(part - 1, autoplay: playing),
                icon: const Icon(Icons.skip_previous_outlined),
              ),
              IconButton.filled(
                tooltip: playing ? 'Pause' : 'Play',
                style: IconButton.styleFrom(
                  backgroundColor: Palette.blue,
                  minimumSize: const Size.square(48),
                ),
                onPressed: busy ? null : play,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(
                tooltip: 'Next passage',
                onPressed: part + 1 == audioExcerpt.length || busy
                    ? null
                    : () => selectPart(part + 1, autoplay: playing),
                icon: const Icon(Icons.skip_next_outlined),
              ),
              const SizedBox(width: 42),
            ],
          ),
        ],
      ),
    );
  }
}
