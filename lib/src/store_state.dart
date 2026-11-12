import 'package:flutter/widgets.dart';

enum StoreTab { library, shop, search, account }

enum ReadingTheme { light, sepia, dark, darkest }

class Book {
  const Book(
    this.title,
    this.author,
    this.category,
    this.price,
    this.year, {
    this.rating = 4.0,
  });

  final String title;
  final String author;
  final String category;
  final int price;
  final int year;
  final double rating;
  String get priceLabel => (price / 100).toStringAsFixed(2);
}

const featuredBook = Book(
  'Fortress of the Stone Dragon: A Branches Book',
  'Tracey West',
  'Children',
  3699,
  2020,
);

const recommendations = [
  Book(
    'Peter & the Wolf',
    'Sergei Prokofiev',
    'Children',
    699,
    1936,
    rating: 4.4,
  ),
  Book('Andreas haus...', 'Mira Lobe', 'Children', 899, 1968, rating: 3.8),
  Book('A man called Ove', 'Fredrik Backman', 'Arts & Literature', 1299, 2012),
];

const catalog = [
  ...recommendations,
  Book('The boy with the...', 'John Boyne', 'Historical', 999, 2006),
  Book('Gulliver Travels', 'Jonathan Swift', 'Children', 499, 1726),
  Book('Lord of the Flies', 'William Golding', 'Children', 1199, 1954),
  Book('When the Doves...', 'Gertrude Chandler Warner', 'Children', 799, 1996),
  featuredBook,
];

const categoryNames = [
  'Arts & Photography',
  'Biographies & Memoirs',
  'Business & Money',
  'Calendars',
  "Children's Books",
  'Christian Books & Bibles',
];

const categoryFilters = [
  'Arts & Literature',
  'Ethnic & National',
  'Historical',
  'Leaders & Notable People',
  'Memoirs',
  'Professionals & Academics',
  'Reference & Collections',
  'Regional Canada',
];

const designSubtitle = 'Magna laboris fugiat ad Lorem sit mollit proident.';
const authorBio =
    'I am the bestselling author of more than 300 books for children and young adults. I currently write the Dragon Masters series for the Scholastic Branches line.';
const featuredIntro =
    'Black-and-white sketch-type drawings add depth to the story and feelings to the characters (both children and dragons). Emergent readers will find happy success here.\n\nThe brief chapters, large print and attractive illustrations make this an inviting story for young readers.';
const readerExcerpt =
    'Nulla nulla deserunt voluptate ullamco id eu adipisicing non. Dolor excepteur eiusmod sit sit eiusmod laboris ut sit do magna mollit deserunt non. Commodo laboris velit dolore qui duis enim elit. Ipsum consectetur eu fugiat culpa ut mollit.\n\nEiusmod qui occaecat duis id elit et esse velit proident aliquip. Eu velit nostrud dolore irure excepteur nisi aute id cillum deserunt duis Lorem nostrud id. Fugiat qui magna aute commodo aute consectetur. Fugiat dolore voluptate ut aliquip sint nulla occaecat reprehenderit nisi mollit non nulla tempor cillum. Exercitation laborum ipsum laborum aliqua non sunt proident officia amet. Nulla aliqua sint occaecat veniam eiusmod duis aute fugiat irure officia excepteur ipsum.\n\nId cillum labore ad ullamco pariatur ullamco esse qui commodo non. Fugiat dolore voluptate ut aliquip sint nulla occaecat.';
const audioExcerpt = [
  'An evil wizard named Astrid is plotting to become the most powerful wizard in the world.',
  'She is collecting ingredients for a dangerous spell, and it is up to the Dragon Masters to stop her from casting it.',
];

class BookReview {
  const BookReview(this.stars, this.text);

  final int stars;
  final String text;
}

class StoreState extends ChangeNotifier {
  bool entered = false;
  StoreTab tab = StoreTab.library;
  Book? current;
  final owned = <Book>{};
  final saved = <Book>{};
  final recent = <Book>{};
  final following = <String>{};
  final bookmarks = <Book>{};
  final reviews = <Book, BookReview>{};
  final readingPages = <Book, int>{};
  final searches = ['Donal', 'Love story', 'Design', 'Fantasy', 'Materia-Art'];
  ReadingTheme readingTheme = ReadingTheme.dark;
  double pageBrightness = .82;
  double readingFontSize = 16;

  void enter() {
    entered = true;
    notifyListeners();
  }

  void signOut() {
    entered = false;
    tab = StoreTab.library;
    notifyListeners();
  }

  void selectTab(StoreTab value) {
    tab = value;
    notifyListeners();
  }

  void view(Book book) {
    recent.remove(book);
    recent.add(book);
    notifyListeners();
  }

  void acquire(Book book) {
    owned.add(book);
    saved.remove(book);
    notifyListeners();
  }

  void read(Book book) {
    current = book;
    notifyListeners();
  }

  int pageOf(Book book) => readingPages[book] ?? 77;

  void updatePage(Book book, int page) {
    readingPages[book] = page;
    notifyListeners();
  }

  void setReadingPreferences({
    ReadingTheme? theme,
    double? brightness,
    double? fontSize,
  }) {
    readingTheme = theme ?? readingTheme;
    pageBrightness = brightness ?? pageBrightness;
    readingFontSize = fontSize ?? readingFontSize;
    notifyListeners();
  }

  void toggleSaved(Book book) => _toggle(saved, book);
  void toggleFollow(String author) => _toggle(following, author);
  void toggleBookmark(Book book) => _toggle(bookmarks, book);

  void _toggle<T>(Set<T> set, T value) {
    if (!set.remove(value)) set.add(value);
    notifyListeners();
  }

  void submitReview(Book book, BookReview review) {
    reviews[book] = review;
    notifyListeners();
  }

  void rememberSearch(String input) {
    final query = input.trim();
    if (query.isEmpty) return;
    searches.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
    searches.insert(0, query);
    if (searches.length > 5) searches.removeLast();
    notifyListeners();
  }
}

class StoreScope extends InheritedNotifier<StoreState> {
  const StoreScope({
    super.key,
    required StoreState super.notifier,
    required super.child,
  });

  static StoreState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
