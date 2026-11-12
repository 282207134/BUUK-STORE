import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'book.dart';
import 'reader.dart';
import 'store_state.dart';
import 'ui.dart';

class StoreHome extends StatelessWidget {
  const StoreHome({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return store.entered
        ? IndexedStack(
            index: store.tab.index,
            children: const [
              LibraryPage(),
              ShopPage(),
              SearchPage(),
              AccountPage(),
            ],
          )
        : const LoginPage();
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final enter = StoreScope.of(context).enter;
    return PageFrame(
      color: Palette.mist,
      background: pixso('login-background', fit: BoxFit.fill),
      body: LayoutBuilder(
        builder: (context, limits) {
          final height = math.max(limits.maxHeight, 680.0);
          return SingleChildScrollView(
            child: SizedBox(
              height: height,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: height * .052,
                    child: Semantics(
                      label: 'BUUK Store',
                      image: true,
                      child: pixso('logo', width: 205),
                    ),
                  ),
                  Positioned(
                    top: height * .525,
                    left: 32,
                    right: 32,
                    child: Column(
                      children: [
                        _SignInButton('google', 'Continue with Google', enter),
                        const SizedBox(height: 24),
                        _SignInButton(
                          'facebook',
                          'Continue with Facebook',
                          enter,
                        ),
                        const SizedBox(height: 30),
                        TextButton(
                          onPressed: enter,
                          child: const Text(
                            'SKIP',
                            style: TextStyle(color: Palette.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    bottom: 16,
                    left: 12,
                    right: 12,
                    child: Text(
                      'App version 1.01\nDesign by thevdesignstudio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Palette.muted,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton(this.asset, this.label, this.onTap);

  final String asset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        foregroundColor: Palette.ink,
        backgroundColor: Colors.white.withValues(alpha: .64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
      ),
      icon: pixso(asset, width: 22, height: 22),
      label: Text(label),
    ),
  );
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  int segment = 0;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final current = store.current;
    final showReading = segment == 0 && current != null;
    final books = segment == 0 ? store.owned : store.saved;
    void open(Book book) => openBook(context, book);
    void shop() => store.selectTab(StoreTab.shop);
    return PageFrame(
      color: showReading ? Palette.mist : Palette.paper,
      bottom: const StoreNav(),
      body: Column(
        children: [
          TopBar(
            center: Segments(
              const ['Book', 'Buy Later'],
              selected: segment,
              onSelect: (index) => setState(() => segment = index),
            ),
          ),
          Expanded(
            child: ListView(
              key: PageStorageKey(segment),
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                if (showReading) ...[
                  _ReadingSummary(current, page: store.pageOf(current)),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
                    child: SectionTitle(
                      'Reading Insights',
                      subtitle: 'See your reading trends & track your progress',
                    ),
                  ),
                  const ReadingChart(),
                  const SizedBox(height: 46),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Palette.paper,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        BookRail(
                          'Recent View',
                          [
                            ...store.recent.toList().reversed,
                            ...recommendations.where(
                              (book) => !store.recent.contains(book),
                            ),
                          ],
                          onBook: open,
                          onMore: () => open(current),
                          sampleProgress: true,
                        ),
                        const SizedBox(height: 36),
                        BookRail('All Book', {...books, current}, onBook: open),
                      ],
                    ),
                  ),
                ] else if (books.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  BookRail(
                    segment == 0 ? 'All Book' : 'Buy Later',
                    books,
                    onBook: open,
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  Center(
                    child: pixso('empty-library', width: 180, height: 144),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    segment == 0
                        ? 'You don’t have a book'
                        : 'You haven’t saved a book',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 19),
                  Center(child: PrimaryButton('Shop now', shop)),
                  const SizedBox(height: 31),
                  BookRail(
                    'Ebook For You',
                    recommendations,
                    onBook: open,
                    onMore: shop,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingSummary extends StatelessWidget {
  const _ReadingSummary(this.book, {required this.page});

  final Book book;
  final int page;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 391,
    child: Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          top: 17,
          left: 18,
          right: -24,
          child: pixso('library-decoration', height: 337, fit: BoxFit.fill),
        ),
        Positioned(
          top: 25,
          left: 17,
          width: 221,
          child: pixso('library-current', height: 319),
        ),
        Positioned(
          right: 35,
          top: 98,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'In progress',
                style: TextStyle(fontSize: 12, color: Palette.muted),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${(page / 352 * 100).round()}'),
                    const TextSpan(
                      text: '  %',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 49,
                  color: Palette.blue,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const Text(
                '25h 20m',
                style: TextStyle(fontSize: 13, color: Palette.muted),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                'Continue',
                () => openReader(context, book),
                height: 36,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    void category(String name) => pushPage(context, CategoryPage(name));
    return PageFrame(
      color: Palette.mist,
      bottom: const StoreNav(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 22),
        children: [
          TopBar(
            trailing: [
              IconButton(
                tooltip: 'Browse categories',
                icon: pixso('category-icon', width: 24),
                onPressed: () => _browse(context, category),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageTitle('Book store'),
                Text(
                  'You can miss a person every day, and still be glad that they are no longer in your life.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Palette.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const _FeaturedBooks(),
          const SizedBox(height: 34),
          for (final title in [
            'Ebook For You',
            'Business',
            'Sci-Fi & Fantasy',
          ]) ...[
            BookRail(
              title,
              recommendations,
              onBook: (book) => openBook(context, book),
              onMore: () =>
                  category(title == 'Ebook For You' ? 'Children' : title),
              sampleProgress: true,
            ),
            const SizedBox(height: 31),
          ],
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Palette.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
                  child: SectionTitle(
                    'All Category',
                    onTap: () => _browse(context, category),
                  ),
                ),
                for (final name in categoryNames)
                  ListTile(
                    title: Text(name, style: const TextStyle(fontSize: 14)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    minTileHeight: 50,
                    onTap: () => category(name),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: TextButton.icon(
                      onPressed: () => _browse(context, category),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('More category'),
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

  Future<void> _browse(BuildContext context, ValueChanged<String> open) async {
    final name = await showPanel<String>(
      context,
      _ChoiceList(title: 'All Category', options: categoryNames),
    );
    if (name != null && context.mounted) open(name);
  }
}

class _FeaturedBooks extends StatelessWidget {
  const _FeaturedBooks();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = math.min(313.0, constraints.maxWidth - 54);
      return SizedBox(
        height: 330,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            SizedBox(
              width: width,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    pixso('featured', fit: BoxFit.fill),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => openBook(context, featuredBook),
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(24, 23, 12, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BEST OF THE WEEK',
                                style: TextStyle(
                                  fontSize: 13,
                                  letterSpacing: 4,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Explore the world',
                                style: TextStyle(
                                  fontSize: 30,
                                  letterSpacing: .8,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Semantics(
              label: 'More featured books',
              button: true,
              child: InkWell(
                onTap: () => pushPage(context, const CategoryPage('Children')),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: pixso(
                    'featured-next',
                    width: width,
                    height: 330,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

enum _Sort {
  publication('Publication date'),
  relevance('Relevance'),
  review('Avg. Customer Review'),
  price('Best Buy'),
  manual('Manual');

  const _Sort(this.label);
  final String label;
}

class CategoryPage extends StatefulWidget {
  const CategoryPage(this.name, {super.key});

  final String name;

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  _Sort sort = _Sort.manual;
  String? filter;

  String get category => switch (widget.name) {
    "Children's Books" => 'Children',
    'Arts & Photography' => 'Arts & Literature',
    'Biographies & Memoirs' => 'Memoirs',
    _ => widget.name,
  };

  List<Book> get books {
    final result = catalog
        .where((book) => book.category == (filter ?? category))
        .toList();
    final compare = switch (sort) {
      _Sort.publication => (Book a, Book b) => b.year.compareTo(a.year),
      _Sort.relevance =>
        (Book a, Book b) => a == b
            ? 0
            : a == featuredBook
            ? -1
            : b == featuredBook
            ? 1
            : a.title.compareTo(b.title),
      _Sort.review => (Book a, Book b) => b.rating.compareTo(a.rating),
      _Sort.price => (Book a, Book b) => a.price.compareTo(b.price),
      _Sort.manual => null,
    };
    if (compare != null) result.sort(compare);
    return result;
  }

  Future<void> chooseSort() async {
    final label = await showPanel<String>(
      context,
      _ChoiceList(
        title: 'Sort',
        options: _Sort.values.map((item) => item.label).toList(),
        selected: sort.label,
        radio: true,
      ),
    );
    if (label != null && mounted) {
      setState(
        () => sort = _Sort.values.firstWhere((item) => item.label == label),
      );
    }
  }

  Future<void> chooseCategory() async {
    final result = await showPanel<String>(
      context,
      _ChoiceList(
        title: 'Select category',
        options: categoryFilters,
        selected: filter,
      ),
    );
    if (result != null && mounted) {
      setState(() => filter = filter == result ? null : result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final items = books;
    return PageFrame(
      color: Colors.white,
      bottom: const StoreNav(),
      body: Column(
        children: [
          TopBar(
            back: true,
            trailing: [
              IconButton(
                tooltip: 'Sort',
                onPressed: chooseSort,
                icon: pixso('sort-icon', width: 24),
              ),
              IconButton(
                tooltip: 'Select category',
                onPressed: chooseCategory,
                icon: pixso('category-icon', width: 24),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 28),
              children: [
                const SizedBox(height: 225),
                PageTitle(filter ?? category, center: true),
                const Text(
                  designSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Palette.muted, fontSize: 13),
                ),
                if (filter != null)
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => filter = null),
                      child: const Text('Clear category'),
                    ),
                  ),
                const SizedBox(height: 24),
                Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      child: pixso('category-decoration', width: 337),
                    ),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No books in this category yet.'),
                        ),
                      )
                    else
                      GridView.builder(
                        primary: false,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisExtent: 247,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 24,
                            ),
                        itemBuilder: (context, index) {
                          final book = items[index];
                          return BookTile(
                            book,
                            onTap: () => openBook(context, book),
                            mark: store.owned.contains(book),
                            progress: store.readingPages[book] == null
                                ? null
                                : store.pageOf(book) / 352,
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceList extends StatelessWidget {
  const _ChoiceList({
    required this.title,
    required this.options,
    this.selected,
    this.radio = false,
  });

  final String title;
  final List<String> options;
  final String? selected;
  final bool radio;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      for (final option in options)
        ListTile(
          minTileHeight: 51,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          selected: option == selected,
          selectedColor: Palette.blue,
          title: Text(option, style: const TextStyle(fontSize: 14)),
          trailing: option == selected
              ? Icon(
                  radio ? Icons.radio_button_checked : Icons.check_circle,
                  color: Palette.blue,
                )
              : radio
              ? const Icon(Icons.radio_button_off, color: Color(0xffd9dde7))
              : null,
          onTap: () => Navigator.pop(context, option),
        ),
    ],
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final controller = TextEditingController();
  String query = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void update(String value) => setState(() => query = value.trim());

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final results = catalog.where(
      (book) => '${book.title} ${book.author} ${book.category}'
          .toLowerCase()
          .contains(query.toLowerCase()),
    );
    void open(Book book) {
      store.rememberSearch(query);
      FocusManager.instance.primaryFocus?.unfocus();
      openBook(context, book);
    }

    return PageFrame(
      color: Colors.white,
      bottom: const StoreNav(),
      body: ListView(
        padding: const EdgeInsets.only(top: 36, bottom: 20),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageTitle('Search'),
                const SizedBox(height: 18),
                TextField(
                  controller: controller,
                  onChanged: update,
                  onSubmitted: store.rememberSearch,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Name category, book, author...',
                    hintStyle: const TextStyle(color: Palette.muted),
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 23,
                      color: Palette.muted,
                    ),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              controller.clear();
                              update('');
                            },
                            icon: const Icon(Icons.close, size: 18),
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xffedf0f6)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                if (query.isEmpty) ...[
                  const SectionTitle('Recent Search', subtitle: null),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final term in store.searches)
                          ActionChip(
                            label: Text(term),
                            onPressed: () {
                              controller.text = term;
                              update(term);
                              store.rememberSearch(term);
                            },
                            labelStyle: const TextStyle(
                              color: Palette.blue,
                              fontSize: 13,
                            ),
                            backgroundColor: Palette.mist,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (query.isEmpty) ...[
            const SizedBox(height: 29),
            BookRail(
              'Highly Recommended',
              recommendations,
              onBook: open,
              sampleProgress: true,
              onMore: () => pushPage(context, const CategoryPage('Children')),
            ),
          ] else if (results.isEmpty)
            const Center(child: Text('No matches found.'))
          else
            for (final book in results)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: pixso('book-small', width: 34),
                title: Text(book.title),
                subtitle: Text(book.author),
                onTap: () => open(book),
              ),
        ],
      ),
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return PageFrame(
      color: Colors.white,
      background: pixso('account-background', fit: BoxFit.fill),
      bottom: const StoreNav(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 52, 24, 24),
        children: [
          const Text(
            'Harry Tran',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Palette.blue,
            ),
          ),
          const Text(
            'Read 10/12 books',
            style: TextStyle(color: Palette.muted),
          ),
          const SizedBox(height: 109),
          for (final item in ['About', 'Terms & Privacy', 'Log out'])
            InkWell(
              onTap: item == 'Log out'
                  ? store.signOut
                  : () => showPanel<void>(
                      context,
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SectionTitle(
                          item,
                          subtitle: item == 'About'
                              ? 'BUUK Store · App version 1.01'
                              : 'This offline demo keeps your session on this device while the app is open.',
                        ),
                      ),
                    ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(item, style: const TextStyle(fontSize: 24)),
              ),
            ),
        ],
      ),
    );
  }
}
