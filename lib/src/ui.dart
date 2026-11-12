import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'store_state.dart';

abstract final class Palette {
  static const ink = Color(0xff404c6d);
  static const muted = Color(0xff8995ad);
  static const blue = Color(0xff4267cd);
  static const orange = Color(0xfff6a04c);
  static const mist = Color(0xfff0f4ff);
  static const paper = Color(0xfff9fbff);
}

Widget pixso(String asset, {double? width, double? height, BoxFit? fit}) =>
    Image.asset(
      'assets/pixso/$asset.png',
      width: width,
      height: height,
      fit: fit,
    );

Future<T?> pushPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.body,
    this.color = Palette.paper,
    this.background,
    this.bottom,
    this.lightStatus = false,
  });

  final Widget body;
  final Color color;
  final Widget? background;
  final Widget? bottom;
  final bool lightStatus;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: lightStatus ? Brightness.light : Brightness.dark,
      statusBarBrightness: lightStatus ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: lightStatus
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
    child: Scaffold(
      backgroundColor: color,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (background case final artwork?)
                ExcludeSemantics(child: artwork),
              Column(
                children: [
                  Expanded(
                    child: SafeArea(
                      bottom: bottom == null,
                      minimum: EdgeInsets.only(
                        top: 44,
                        bottom: bottom == null ? 16 : 0,
                      ),
                      child: body,
                    ),
                  ),
                  ?bottom,
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    this.back = false,
    this.trailing = const [],
    this.center,
  });

  final bool back;
  final List<Widget> trailing;
  final Widget? center;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Stack(
      alignment: Alignment.center,
      children: [
        ?center,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (back)
              IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.west, size: 20, color: Palette.muted),
              )
            else
              const SizedBox(width: 48),
            Row(mainAxisSize: MainAxisSize.min, children: trailing),
          ],
        ),
      ],
    ),
  );
}

class StoreNav extends StatelessWidget {
  const StoreNav({super.key, this.current, this.onResume});

  final Book? current;
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final labels = [
      'My Library',
      current == null ? 'Book Store' : 'Store',
      'Search',
      'Account',
    ];
    const assets = ['nav-library', 'nav-store', 'nav-search'];
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Padding(
          padding: EdgeInsets.only(top: current == null ? 0 : 38),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xffedf0f6))),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 26),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    for (final tab in StoreTab.values) ...[
                      if (tab == StoreTab.search && current != null)
                        const SizedBox(width: 44),
                      Expanded(
                        child: Semantics(
                          selected: store.tab == tab,
                          button: true,
                          child: InkResponse(
                            onTap: () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              store.selectTab(tab);
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (tab == StoreTab.account)
                                  Icon(
                                    store.tab == tab
                                        ? Icons.person_rounded
                                        : Icons.person_outline,
                                    size: 24,
                                    color: store.tab == tab
                                        ? Palette.blue
                                        : Palette.muted,
                                  )
                                else
                                  pixso(
                                    assets[tab.index] +
                                        (store.tab == tab ? '-active' : ''),
                                    width: 24,
                                    height: 24,
                                  ),
                                const SizedBox(height: 3),
                                Text(
                                  labels[tab.index],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: store.tab == tab
                                        ? Palette.blue
                                        : Palette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (current case final book?)
          Positioned(
            top: 0,
            width: 48,
            height: 75,
            child: Semantics(
              button: true,
              label: 'Resume ${book.title}',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onResume,
                child: pixso('book-small'),
              ),
            ),
          ),
      ],
    );
  }
}

class Segments extends StatelessWidget {
  const Segments(
    this.labels, {
    super.key,
    required this.selected,
    required this.onSelect,
    this.width = 241,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 30,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      children: [
        for (var index = 0; index < labels.length; index++)
          Expanded(
            child: Semantics(
              selected: selected == index,
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => onSelect(index),
                child: Container(
                  decoration: selected == index
                      ? BoxDecoration(
                          border: Border.all(color: Palette.blue),
                          borderRadius: BorderRadius.circular(30),
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 14,
                      color: selected == index ? Palette.blue : Palette.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label,
    this.onPressed, {
    super.key,
    this.height = 43,
    this.full = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool full;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: full ? double.infinity : null,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Palette.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(full ? 0 : 8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
      child: Text(label),
    ),
  );
}

class BottomAction extends StatelessWidget {
  const BottomAction(this.label, this.onPressed, {super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Palette.blue,
    child: SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 26),
      child: PrimaryButton(label, onPressed, height: 57, full: true),
    ),
  );
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.title, {super.key, this.center = false});

  final String title;
  final bool center;

  @override
  Widget build(BuildContext context) => Text(
    title,
    textAlign: center ? TextAlign.center : TextAlign.start,
    style: const TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w300,
      height: 1.12,
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.subtitle = designSubtitle,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Palette.muted, size: 17),
          ],
        ),
        if (subtitle case final copy?) ...[
          const SizedBox(height: 6),
          Text(
            copy,
            style: const TextStyle(fontSize: 13, color: Palette.muted),
          ),
        ],
      ],
    ),
  );
}

class Stars extends StatelessWidget {
  const Stars({super.key, this.count = 4, this.size = 14});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$count out of 5 stars',
    child: ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 5; i++)
            Icon(
              i < count ? Icons.star : Icons.star_border,
              size: size,
              color: Palette.muted,
            ),
        ],
      ),
    ),
  );
}

class BookTile extends StatelessWidget {
  const BookTile(
    this.book, {
    super.key,
    required this.onTap,
    this.mark = false,
    this.progress,
  });

  final Book book;
  final VoidCallback onTap;
  final bool mark;
  final double? progress;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              pixso('book-small', fit: BoxFit.contain),
              if (mark)
                const Positioned(
                  bottom: 14,
                  child: Icon(
                    Icons.check_circle,
                    color: Palette.blue,
                    size: 26,
                  ),
                )
              else if (progress case final value?)
                Positioned(
                  bottom: 13,
                  left: 18,
                  right: 18,
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white,
                    backgroundColor: const Color(0xffd6d7da),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(
          book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 4),
        Stars(count: book.rating.round(), size: 11),
      ],
    ),
  );
}

class BookRail extends StatelessWidget {
  const BookRail(
    this.title,
    this.books, {
    super.key,
    required this.onBook,
    this.onMore,
    this.sampleProgress = false,
  });

  final String title;
  final Iterable<Book> books;
  final ValueChanged<Book> onBook;
  final VoidCallback? onMore;
  final bool sampleProgress;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final items = books.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SectionTitle(title, onTap: onMore),
        ),
        const SizedBox(height: 25),
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 25),
            itemBuilder: (_, i) {
              final book = items[i];
              return SizedBox(
                width: 135,
                child: BookTile(
                  book,
                  onTap: () => onBook(book),
                  mark: store.owned.contains(book),
                  progress: store.readingPages.containsKey(book)
                      ? store.pageOf(book) / 352
                      : sampleProgress && i == 1
                      ? .45
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<T?> showPanel<T>(
  BuildContext context,
  Widget child, {
  double shade = .52,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: Colors.black.withValues(alpha: shade),
  builder: (context) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 540,
        maxHeight: MediaQuery.sizeOf(context).height * .87,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 23),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Palette.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    ),
  ),
);

class ReadingChart extends StatelessWidget {
  const ReadingChart({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 100,
        width: double.infinity,
        child: CustomPaint(painter: _ReadingCurve()),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final week in ['W1', 'W2', 'W3', 'W4', 'W5', 'This Week'])
              Text(
                week,
                style: const TextStyle(fontSize: 11, color: Palette.muted),
              ),
          ],
        ),
      ),
    ],
  );
}

class _ReadingCurve extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final end = Offset(w * .88, 24);
    final curve = Path()
      ..moveTo(0, h * .87)
      ..cubicTo(w * .19, h * .35, w * .22, h * .97, w * .37, h * .57)
      ..cubicTo(w * .48, h * .22, w * .49, h * .48, w * .62, h * .61)
      ..cubicTo(w * .77, h * .81, w * .77, h * .32, end.dx, end.dy);
    final area = Path.from(curve)
      ..lineTo(end.dx, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: .9),
            Palette.mist.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..shader = const LinearGradient(
          colors: [Color(0xffffccaf), Palette.blue],
        ).createShader(Rect.fromLTWH(0, 0, end.dx, h)),
    );
    canvas.drawCircle(end, 5, Paint()..color = Palette.blue);
    canvas.drawCircle(end, 2, Paint()..color = Colors.white);
    final badge = Rect.fromLTWH(math.max(0, end.dx - 45), end.dy - 13, 35, 27);
    canvas.drawRRect(
      RRect.fromRectAndRadius(badge, const Radius.circular(4)),
      Paint()..color = Palette.blue,
    );
    (TextPainter(
      text: const TextSpan(
        text: '4 hrs',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout()).paint(canvas, badge.topLeft + const Offset(4, 6));
  }

  @override
  bool shouldRepaint(covariant _ReadingCurve oldDelegate) => false;
}
