import 'package:flutter/material.dart';

import 'reader.dart';
import 'store_state.dart';
import 'ui.dart';

void openBook(BuildContext context, Book book) {
  StoreScope.of(context).view(book);
  pushPage(context, BookPage(book));
}

class BookPage extends StatefulWidget {
  const BookPage(this.book, {super.key});

  final Book book;

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  bool audio = false;
  bool expanded = false;

  Book get book => widget.book;

  void showAuthor() => pushPage(context, AuthorPage(book));

  Future<void> checkout({bool gift = false}) async {
    final confirmed = await showPanel<bool>(
      context,
      _CheckoutPanel(book, gift: gift),
      shade: .48,
    );
    if (confirmed != true || !mounted) return;
    if (gift) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo gift order confirmed')),
      );
      return;
    }
    StoreScope.of(context).acquire(book);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Added to My Library')));
  }

  void preview() => showAudioPreview(context, book);

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final current = store.current;
    final compact = !audio && current == book;
    final owned = store.owned.contains(book);
    final saved = store.saved.contains(book);
    final review = store.reviews[book];
    return PageFrame(
      color: Palette.mist,
      background: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: double.infinity,
          height: 715,
          child: pixso('book-background', fit: BoxFit.fill),
        ),
      ),
      bottom: StoreNav(
        current: compact ? current : null,
        onResume: compact ? () => openReader(context, book) : null,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 18),
            children: [
              SizedBox(
                height: 328,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      child: pixso('book-detail', width: 243, height: 348),
                    ),
                    if (audio)
                      Positioned(
                        bottom: 31,
                        child: IconButton(
                          tooltip: 'Play audio sample',
                          padding: EdgeInsets.zero,
                          onPressed: preview,
                          icon: pixso('book-play', width: 60),
                        ),
                      ),
                  ],
                ),
              ),
              Center(
                child: Segments(
                  const ['Ebook', 'Audio'],
                  width: 198,
                  selected: audio ? 1 : 0,
                  onSelect: (index) => setState(() => audio = index == 1),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      book.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, height: 1.2),
                    ),
                    const SizedBox(height: 3),
                    TextButton(
                      onPressed: showAuthor,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'by ',
                              style: TextStyle(color: Palette.muted),
                            ),
                            TextSpan(
                              text: book.author,
                              style: const TextStyle(color: Palette.blue),
                            ),
                          ],
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Stars(),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            compact
                                ? '4.0 (283,749 reviewers)'
                                : '4.0 of 5 (283,749 ratings)',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Palette.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _GetBookButton(
                      price: owned ? null : book.priceLabel,
                      label: owned
                          ? (audio ? 'Listen' : 'Read now')
                          : 'Get Now',
                      onTap: owned
                          ? (audio ? preview : () => openReader(context, book))
                          : () => checkout(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _BookAction(
                          'Free Trial',
                          'trial-icon',
                          audio ? preview : () => openReader(context, book),
                        ),
                        _BookAction(
                          'Gift',
                          'gift-icon',
                          () => checkout(gift: true),
                        ),
                        _BookAction(
                          saved ? 'Saved' : 'Buy Later',
                          'save-icon',
                          () => store.toggleSaved(book),
                          selected: saved,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 55 : 27),
              if (!audio)
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Palette.paper,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle('Intro', subtitle: null),
                            const SizedBox(height: 14),
                            Text(
                              book == featuredBook
                                  ? featuredIntro
                                  : '${book.title} by ${book.author}. Browse the sample or save this title to your library.',
                              maxLines: expanded ? null : 7,
                              overflow: expanded ? null : TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.65,
                              ),
                            ),
                            if (book == featuredBook)
                              TextButton(
                                onPressed: () =>
                                    setState(() => expanded = !expanded),
                                child: Text(expanded ? 'See less' : 'See more'),
                              ),
                            const SizedBox(height: 12),
                            SectionTitle('Author', onTap: showAuthor),
                            const SizedBox(height: 22),
                            InkWell(
                              onTap: showAuthor,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    pixso('author-avatar', width: 76),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Text(
                                        book.author,
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Palette.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const SectionTitle(
                              'High Recommend',
                              subtitle: null,
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                Text(
                                  review == null ? '4.0' : '${review.stars}.0',
                                  style: const TextStyle(fontSize: 33),
                                ),
                                const SizedBox(width: 12),
                                Stars(count: review?.stars ?? 4),
                                const Spacer(),
                                PrimaryButton(
                                  'Review',
                                  () => pushPage(context, ReviewPage(book)),
                                  height: 36,
                                ),
                              ],
                            ),
                            if (review != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                review.text,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Align(alignment: Alignment.topLeft, child: TopBar(back: true)),
        ],
      ),
    );
  }
}

class _GetBookButton extends StatelessWidget {
  const _GetBookButton({
    required this.price,
    required this.label,
    required this.onTap,
  });

  final String? price;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3d4267cd),
          blurRadius: 22,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Material(
      color: Palette.blue,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            if (price case final value?)
              ClipPath(
                clipper: _PriceTag(),
                child: Container(
                  width: 114,
                  height: 50,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Palette.orange, Color(0xffffb765)],
                    ),
                  ),
                  child: Text(
                    '\$$value',
                    style: const TextStyle(
                      fontSize: 21,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PriceTag extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width * .72, 0)
    ..cubicTo(
      size.width * .57,
      13,
      size.width * 1.22,
      10,
      size.width * .87,
      size.height,
    )
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant _PriceTag oldClipper) => false;
}

class _BookAction extends StatelessWidget {
  const _BookAction(
    this.label,
    this.asset,
    this.onTap, {
    this.selected = false,
  });

  final String label;
  final String asset;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Flexible(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              const Icon(Icons.favorite, color: Palette.blue, size: 23)
            else
              pixso(asset, width: 23),
            const SizedBox(width: 5),
            Flexible(child: Text(label, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    ),
  );
}

class AuthorPage extends StatefulWidget {
  const AuthorPage(this.book, {super.key});

  final Book book;

  @override
  State<AuthorPage> createState() => _AuthorPageState();
}

class _AuthorPageState extends State<AuthorPage> {
  int slide = 0;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final book = widget.book;
    final following = store.following.contains(book.author);
    final isFeatured = book == featuredBook;
    return PageFrame(
      color: Palette.mist,
      lightStatus: false,
      bottom: BottomAction(
        following ? 'Following' : 'Follow',
        () => store.toggleFollow(book.author),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 7, bottom: 24),
            children: [
              Center(child: pixso('author-avatar', width: 94)),
              const SizedBox(height: 8),
              Text(
                book.author,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
              if (isFeatured)
                Text(
                  following ? '6,229 followers' : '6,228 followers',
                  textAlign: TextAlign.center,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 31, 24, 24),
                child: Text(
                  isFeatured ? authorBio : 'Explore books by ${book.author}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.62),
                ),
              ),
              SizedBox(
                height: 347,
                child: PageView.builder(
                  itemCount: 4,
                  onPageChanged: (index) => setState(() => slide = index),
                  itemBuilder: (context, index) => InkWell(
                    onTap: () => openBook(
                      context,
                      index == 0 ? book : recommendations[index - 1],
                    ),
                    child: OverflowBox(
                      minWidth: 467,
                      maxWidth: 467,
                      alignment: Alignment(index.isEven ? 0 : .5, 0),
                      child: pixso('author-books', width: 467),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < 4; index++)
                    Container(
                      width: index == slide ? 10 : 6,
                      height: index == slide ? 10 : 6,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: index == slide ? Palette.ink : Palette.muted,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 38),
              BookRail(
                isFeatured ? 'Look Around Her Corner' : 'More Books',
                recommendations,
                onBook: (title) => openBook(context, title),
                onMore: () => openBook(context, book),
              ),
            ],
          ),
          const Align(alignment: Alignment.topLeft, child: TopBar(back: true)),
        ],
      ),
    );
  }
}

class ReviewPage extends StatefulWidget {
  const ReviewPage(this.book, {super.key});

  final Book book;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final text = TextEditingController();
  int rating = 4;
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final previous = StoreScope.of(context).reviews[widget.book];
    if (previous != null) {
      rating = previous.stars;
      text.text = previous.text;
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  void submit() {
    StoreScope.of(
      context,
    ).submitReview(widget.book, BookReview(rating, text.text.trim()));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const copy = [
      'I didn’t enjoy it',
      'It was okay',
      'I liked it',
      'More than I can say!',
      'I loved it!',
    ];
    return PageFrame(
      color: Palette.mist,
      bottom: BottomAction('Submit', submit),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: Column(
            children: [
              const TopBar(back: true),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: PageTitle('How much do you\nlove this?', center: true),
              ),
              const SizedBox(height: 31),
              Text(
                copy[rating - 1],
                style: const TextStyle(color: Palette.blue, fontSize: 16),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var star = 1; star <= 5; star++)
                    IconButton(
                      tooltip: 'Rate $star out of 5',
                      onPressed: () => setState(() => rating = star),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 49,
                      ),
                      icon: Icon(
                        star <= rating ? Icons.star : Icons.star_border,
                        color: star <= rating ? Palette.orange : Palette.muted,
                        size: 34,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: (constraints.maxHeight - 242)
                    .clamp(150, 800)
                    .toDouble(),
                child: ColoredBox(
                  color: Palette.paper,
                  child: TextField(
                    controller: text,
                    expands: true,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      hintText: 'Write your review',
                      hintStyle: TextStyle(color: Palette.muted),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutPanel extends StatelessWidget {
  const _CheckoutPanel(this.book, {required this.gift});

  final Book book;
  final bool gift;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 21,
              color: Palette.ink,
            ),
            const SizedBox(width: 6),
            Text(gift ? 'Gift' : 'Pay', style: const TextStyle(fontSize: 20)),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
        const _PaymentRow('Card', 'Demo card\n••• 2345', Icons.credit_card),
        const _PaymentRow('Shipping', 'Digital delivery'),
        const _PaymentRow('Contact', 'reader@example.com'),
        const Divider(height: 28, color: Color(0xffedf0f6)),
        _PriceLine('Subtotal', book.priceLabel),
        const _PriceLine('Sale tax', '0.00'),
        const _PriceLine('Shipping', '0.00'),
        _PriceLine('Total', book.priceLabel, total: true),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Column(
            children: [
              Icon(
                Icons.face_retouching_natural,
                size: 42,
                color: Palette.blue,
              ),
              SizedBox(height: 5),
              Text(
                'Confirm demo checkout',
                style: TextStyle(color: Palette.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow(this.label, this.value, [this.icon]);

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 74,
          child: icon == null
              ? Text(
                  label,
                  style: const TextStyle(color: Palette.muted, fontSize: 13),
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(icon, color: const Color(0xffad2726), size: 34),
                ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, height: 1.3)),
        ),
      ],
    ),
  );
}

class _PriceLine extends StatelessWidget {
  const _PriceLine(this.label, this.value, {this.total = false});

  final String label;
  final String value;
  final bool total;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 74, top: 5, bottom: 5),
    child: DefaultTextStyle(
      style: TextStyle(
        color: total ? Palette.ink : Palette.muted,
        fontSize: total ? 20 : 14,
        fontWeight: total ? FontWeight.w600 : FontWeight.w400,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text('\$$value')],
      ),
    ),
  );
}
