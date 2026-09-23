import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class AppTheme {
  static const Color charcoal = Color(0xFF1B1B1B);
  static const Color charcoalSoft = Color(0xFF2A2A2A);
  static const Color gold = Color(0xFFBAA06A);
  static const Color goldSoft = Color(0xFFD9C699);
  static const Color paper = Color(0xFFF5F0E8);
  static const Color ink = Color(0xFF1E1E1E);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F0EA),
      primaryColor: gold,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.light,
        primary: gold,
        secondary: goldSoft,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF4F0EA),
        foregroundColor: ink,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: charcoal,
      primaryColor: gold,
      colorScheme: ColorScheme.fromSeed(
        seedColor: gold,
        brightness: Brightness.dark,
        primary: gold,
        secondary: goldSoft,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: charcoal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: charcoalSoft,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class Law {
  final int id;
  final String name;
  final String category;
  final String summary;

  Law({required this.id, required this.name, required this.category, required this.summary});

  factory Law.fromMap(Map<String, dynamic> map) {
    return Law(
      id: map['id'] as int,
      name: map['name'] as String,
      category: map['category'] as String,
      summary: map['summary'] as String,
    );
  }
}

class Article {
  final int id;
  final int lawId;
  final int articleNumber;
  final String chapter;
  final String section;
  final String title;
  final String body;

  Article({
    required this.id,
    required this.lawId,
    required this.articleNumber,
    required this.chapter,
    required this.section,
    required this.title,
    required this.body,
  });

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'] as int,
      lawId: map['law_id'] as int,
      articleNumber: map['article_number'] as int,
      chapter: map['chapter'] as String,
      section: map['section'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
    );
  }
}

class SearchResult {
  final int id;
  final String lawName;
  final int articleNumber;
  final String excerpt;
  final int lawId;

  SearchResult({
    required this.id,
    required this.lawName,
    required this.articleNumber,
    required this.excerpt,
    required this.lawId,
  });
}

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'yemen_laws.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
    await _seedData();
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE laws (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        category TEXT,
        summary TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE articles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        law_id INTEGER,
        article_number INTEGER,
        chapter TEXT,
        section TEXT,
        title TEXT,
        body TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        article_id INTEGER,
        law_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE recent_reads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        law_id INTEGER,
        article_id INTEGER,
        opened_at TEXT
      )
    ''');
  }

  Future<void> _seedData() async {
    final db = await database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM laws')) ?? 0;
    if (count > 0) return;

    final laws = [
      {'id': 1, 'name': 'قانون المرافعات المدنية والتجارية', 'category': 'مرافعات', 'summary': 'تنظيم الإجراءات في المحاكم المدنية والتجارية.'},
      {'id': 2, 'name': 'قانون العقوبات', 'category': 'جزائي', 'summary': 'تحديد الجرائم والعقوبات والجزاءات.'},
      {'id': 3, 'name': 'قانون التجارة', 'category': 'تجاري', 'summary': 'تحديد المعاملات التجارية والعقود.'},
      {'id': 4, 'name': 'قانون الأحوال الشخصية', 'category': 'أحوال شخصية', 'summary': 'المسائل الأسرية والحقوق الزوجية.'},
      {'id': 5, 'name': 'قانون العمل', 'category': 'عمل', 'summary': 'العلاقات الوظيفية والأجور والتزامات العمل.'},
      {'id': 6, 'name': 'قانون الإثبات', 'category': 'إثبات', 'summary': 'أساليب إثبات الحقوق والالتزامات.'},
    ];

    final articles = [
      {'law_id': 1, 'article_number': 1, 'chapter': 'الباب الأول', 'section': 'الموضوع', 'title': 'مبدأ التقاضي', 'body': 'لكل ذي مصلحة حق اللجوء إلى القضاء للإدعاء على حقوقه وفق أحكام القانون.'},
      {'law_id': 1, 'article_number': 2, 'chapter': 'الباب الأول', 'section': 'الموضوع', 'title': 'الاختصاص', 'body': 'تختص المحاكم بنظر المنازعات الداخلة في اختصاصها وفقاً لأحكام هذا القانون.'},
      {'law_id': 1, 'article_number': 319, 'chapter': 'الباب الثالث', 'section': 'التنفيذ', 'title': 'التنفيذ الجبري', 'body': 'يُنفذ الحكم بطريق التنفيذ الجبري عند عدم التنفيذ الطوعي، بما يضمن تنفيذ الحقوق المقررة.'},
      {'law_id': 2, 'article_number': 25, 'chapter': 'الباب الأول', 'section': 'الموارد', 'title': 'الجرم', 'body': 'كل فعل يشكل مخالفة لنص قانوني معين يعتبر جريمة إذا نظم له القانون عقوبة.'},
      {'law_id': 2, 'article_number': 74, 'chapter': 'الباب الثاني', 'section': 'العقوبة', 'title': 'العقوبة', 'body': 'تحدد العقوبة وفق ما يقرره القانون مع مراعاة ظروف الجريمة وشخصية الجاني.'},
      {'law_id': 3, 'article_number': 1, 'chapter': 'الباب الأول', 'section': 'التجارة', 'title': 'التجارة', 'body': 'تعد المعاملات التجارية كل ما يرتبط بالنشاط الاقتصادي والتجاري وفق أحكام القانون.'},
      {'law_id': 3, 'article_number': 22, 'chapter': 'الباب الثاني', 'section': 'العقود', 'title': 'عقد البيع', 'body': 'يُعد عقد البيع عقداً يلتزم بمقتضاه البائع بتسليم المبيع والثمن المترتب.'},
      {'law_id': 4, 'article_number': 4, 'chapter': 'الباب الأول', 'section': 'الزواج', 'title': 'شرعية الزواج', 'body': 'يُشترط في الزواج إقرار الرضا، وقيام الضوابط الشرعية والقانونية.'},
      {'law_id': 4, 'article_number': 45, 'chapter': 'الباب الثاني', 'section': 'النفقة', 'title': 'النفقة', 'body': 'تُسدد النفقة بحسب القدرة والاحتياج وفق ما يقرره الشرع والقانون.'},
      {'law_id': 5, 'article_number': 40, 'chapter': 'الباب الثاني', 'section': 'العقد', 'title': 'عقد العمل', 'body': 'يلتزم العامل بأداء العمل وفق ما يتفق عليه، ويلتزم صاحب العمل بأداء الأجر.'},
      {'law_id': 5, 'article_number': 90, 'chapter': 'الباب الثالث', 'section': 'الأجر', 'title': 'استحقاق الأجر', 'body': 'يستحق العامل الأجر كاملاً عن الوقت الذي يشتغل فيه وفق العقد.'},
      {'law_id': 6, 'article_number': 10, 'chapter': 'الباب الأول', 'section': 'الإثبات', 'title': 'أدلة الإثبات', 'body': 'يُثبت الحق بالأدلة المقررة شرعاً وقانوناً، بما في ذلك الكتابة والشهادة والقرائن.'},
      {'law_id': 6, 'article_number': 14, 'chapter': 'الباب الأول', 'section': 'الإثبات', 'title': 'الإقرار', 'body': 'يعتبر الإقرار حجة على المقر ما لم يثبت بطلانه أو عدم صحته.'},
    ];

    final batch = db.batch();
    for (final law in laws) {
      batch.insert('laws', law, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final article in articles) {
      batch.insert('articles', article, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }

  Future<List<Law>> getLaws() async {
    final db = await database;
    final rows = await db.query('laws', orderBy: 'id ASC');
    return rows.map((e) => Law.fromMap(e)).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT DISTINCT category FROM laws ORDER BY category ASC');
    return rows.map((e) => e['category'] as String).toList();
  }

  Future<List<Article>> getArticlesByLaw(int lawId) async {
    final db = await database;
    final rows = await db.query(
      'articles',
      where: 'law_id = ?',
      whereArgs: [lawId],
      orderBy: 'article_number ASC',
    );
    return rows.map((e) => Article.fromMap(e)).toList();
  }

  Future<Article?> getArticleById(int id) async {
    final db = await database;
    final rows = await db.query('articles', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Article.fromMap(rows.first);
  }

  Future<List<SearchResult>> searchArticles(String query) async {
    final db = await database;
    final cleaned = query.trim();
    if (cleaned.isEmpty) return [];
    final likeQuery = cleaned.replaceAll("'", "''").toLowerCase();

    final rows = await db.rawQuery('''
      SELECT a.id, a.article_number, a.body, l.name AS law_name, a.law_id
      FROM articles a
      JOIN laws l ON l.id = a.law_id
      WHERE lower(l.name) LIKE '%$likeQuery%'
         OR lower(CAST(a.article_number AS TEXT)) LIKE '%$likeQuery%'
         OR lower(a.body) LIKE '%$likeQuery%'
         OR lower(a.title) LIKE '%$likeQuery%'
      ORDER BY a.article_number ASC
      LIMIT 30
    ''');

    final results = <SearchResult>[];
    for (final row in rows) {
      final body = (row['body'] as String).replaceAll('\n', ' ');
      final excerpt = body.length > 140 ? '${body.substring(0, 140)}...' : body;
      results.add(SearchResult(
        id: row['id'] as int,
        lawName: row['law_name'] as String,
        articleNumber: row['article_number'] as int,
        excerpt: excerpt,
        lawId: row['law_id'] as int,
      ));
    }
    return results;
  }

  Future<void> toggleFavorite(int articleId, int lawId) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      where: 'article_id = ?',
      whereArgs: [articleId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      await db.delete('favorites', where: 'article_id = ?', whereArgs: [articleId]);
    } else {
      await db.insert('favorites', {'article_id': articleId, 'law_id': lawId});
    }
  }

  Future<bool> isFavorite(int articleId) async {
    final db = await database;
    final rows = await db.query(
      'favorites',
      where: 'article_id = ?',
      whereArgs: [articleId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<Article>> getFavorites() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.*
      FROM articles a
      INNER JOIN favorites f ON f.article_id = a.id
      ORDER BY a.article_number ASC
    ''');
    return rows.map((e) => Article.fromMap(e)).toList();
  }

  Future<void> addNote(String text) async {
    final db = await database;
    await db.insert('notes', {
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;
    return db.query('notes', orderBy: 'created_at DESC');
  }

  Future<void> recordRead(int lawId, int articleId) async {
    final db = await database;
    await db.insert('recent_reads', {
      'law_id': lawId,
      'article_id': articleId,
      'opened_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getRecentReads() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT rr.*, l.name AS law_name, a.article_number, a.title
      FROM recent_reads rr
      JOIN laws l ON l.id = rr.law_id
      JOIN articles a ON a.id = rr.article_id
      ORDER BY rr.id DESC
      LIMIT 5
    ''');
    return rows;
  }
}

class YemenLawApp extends StatefulWidget {
  const YemenLawApp({super.key});

  @override
  State<YemenLawApp> createState() => _YemenLawAppState();
}

class _YemenLawAppState extends State<YemenLawApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    AppDatabase.instance.database;
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'dark';
    setState(() {
      _themeMode = switch (mode) {
        'light' => ThemeMode.light,
        'auto' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'قوانين اليمن',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox(),
        );
      },
      home: _ready ? const SplashScreen() : const Scaffold(backgroundColor: AppTheme.charcoal),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () => setState(() => _progress = 0.35));
    Future.delayed(const Duration(milliseconds: 800), () => setState(() => _progress = 0.7));
    Future.delayed(const Duration(milliseconds: 1400), () => setState(() => _progress = 1.0));
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoal,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.balance, size: 88, color: AppTheme.gold),
            const SizedBox(height: 18),
            const Text(
              'قوانين اليمن',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppTheme.gold,
              ),
            ),
            const Text(
              'Yemen Law',
              style: TextStyle(fontSize: 22, color: AppTheme.goldSoft, letterSpacing: 1.1),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'أسامة المقبلي\nللاستشارات القانونية\n777001515',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.goldSoft, height: 1.8),
            ),
            const SizedBox(height: 18),
            const Text('حقوق الطبع محفوظة', style: TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.charcoalSoft : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.gold.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.gold, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _sections = [
    {'icon': Icons.balance, 'title': 'القوانين اليمنية', 'subtitle': 'جميع القوانين، التصنيفات، البحث، آخر ما قرأته', 'route': 'laws'},
    {'icon': Icons.library_books, 'title': 'المراجع القانونية', 'subtitle': 'كتب، شروحات، أبحاث، رسائل ومذكرات', 'route': 'references'},
    {'icon': Icons.gavel, 'title': 'أحكام المحكمة العليا', 'subtitle': 'أحكام مدنية، تجارية، جزائية، مبادئ قضائية', 'route': 'judgments'},
    {'icon': Icons.description, 'title': 'المذكرات والنماذج القانونية', 'subtitle': 'صحائف دعاوى، مذكرات دفاع، عقود وإنذارات', 'route': 'templates'},
    {'icon': Icons.star, 'title': 'المفضلة', 'subtitle': 'مواد، أحكام، مراجع محفوظة محلياً', 'route': 'favorites'},
    {'icon': Icons.contact_mail, 'title': 'التواصل والاستشارات', 'subtitle': 'أسامة خالد المقبلي - 777001515', 'route': 'contact'},
    {'icon': Icons.note_alt, 'title': 'الملاحظات واقتراحات', 'subtitle': 'أرسل ملاحظاتك واقتراحاتك', 'route': 'notes'},
  ];

  List<SearchResult> _searchResults = [];
  List<Map<String, dynamic>> _recentReads = [];
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadRecentReads();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'dark';
    setState(() {
      _themeMode = switch (mode) {
        'light' => ThemeMode.light,
        'auto' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
    });
  }

  Future<void> _loadRecentReads() async {
    final reads = await AppDatabase.instance.getRecentReads();
    setState(() => _recentReads = reads);
  }

  Future<void> _performSearch(String value) async {
    final searchText = value.trim();
    if (searchText.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await AppDatabase.instance.searchArticles(searchText);
    setState(() => _searchResults = results);
  }

  Future<void> _setTheme(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode);
    setState(() {
      _themeMode = switch (mode) {
        'light' => ThemeMode.light,
        'auto' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
    });
  }

  Future<bool> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('هل تريد الخروج من التطبيق؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('خروج')),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _confirmExit(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('قوانين اليمن', style: TextStyle(fontWeight: FontWeight.w700)),
          actions: [
            PopupMenuButton<String>(
              onSelected: _setTheme,
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'dark', child: Text('الوضع الليلي')),
                PopupMenuItem(value: 'light', child: Text('الوضع النهاري')),
                PopupMenuItem(value: 'auto', child: Text('تلقائي')),
              ],
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'موسوعة قانونية يمنية',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  onChanged: _performSearch,
                  decoration: InputDecoration(
                    hintText: 'ابحث باسم القانون، رقم المادة، أو نص المادة',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: _searchResults.map((result) {
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LawDetailScreen(lawId: result.lawId, articleId: result.id),
                              ),
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(result.lawName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text('المادة ${result.articleNumber}', style: const TextStyle(color: AppTheme.gold)),
                                const SizedBox(height: 8),
                                Text(result.excerpt, textAlign: TextAlign.justify),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (_recentReads.isNotEmpty) ...[
                  const Text('آخر ما قرأت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ..._recentReads.map((entry) {
                    return Card(
                      child: ListTile(
                        title: Text(entry['law_name'] ?? ''),
                        subtitle: Text('المادة ${entry['article_number']} - ${entry['title']}'),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LawDetailScreen(
                              lawId: entry['law_id'] as int,
                              articleId: entry['article_id'] as int,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sections.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 14,
                    childAspectRatio: 3.5,
                  ),
                  itemBuilder: (context, index) {
                    final item = _sections[index];
                    return SectionCard(
                      icon: item['icon'],
                      title: item['title'],
                      subtitle: item['subtitle'],
                      onTap: () {
                        switch (item['route']) {
                          case 'laws':
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LawListScreen()));
                            break;
                          case 'references':
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReferenceScreen()));
                            break;
                          case 'judgments':
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmptyInfoScreen(title: 'أحكام المحكمة العليا')));
                            break;
                          case 'templates':
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmptyInfoScreen(title: 'المذكرات والنماذج القانونية')));
                            break;
                          case 'favorites':
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
                            break;
                          case 'contact':
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactScreen()));
                            break;
                          case 'notes':
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotesScreen()));
                            break;
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'هذا البرنامج هو عبارة عن مجهود شخصي، وهو إهداء إلى روح من هداني إلى طلب العلم، والدي، رحمة الله عليه.',
                    textAlign: TextAlign.justify,
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Column(
                    children: const [
                      Text('أسامة المقبلي', style: TextStyle(fontSize: 12, color: AppTheme.gold)),
                      Text('للاستشارات القانونية', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text('777001515', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      SizedBox(height: 10),
                      Text('حقوق الطبع محفوظة', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EmptyInfoScreen extends StatelessWidget {
  final String title;

  const EmptyInfoScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'قريبًا سيتم إضافة المحتوى',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  final List<String> _items = const [
    'كتب قانونية',
    'شروحات القوانين',
    'أبحاث قانونية',
    'رسائل ماجستير ودكتوراه',
    'مذكرات قانونية جاهزة',
    'نماذج الدعاوى',
    'نماذج العقود',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المراجع القانونية')),
      body: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_items[index]),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () => showDialog(
              context: context,
              builder: (_) => const AlertDialog(content: Text('قريبًا سيتم إضافة المحتوى')),
            ),
          );
        },
      ),
    );
  }
}

class LawListScreen extends StatefulWidget {
  const LawListScreen({super.key});

  @override
  State<LawListScreen> createState() => _LawListScreenState();
}

class _LawListScreenState extends State<LawListScreen> {
  List<Law> _laws = [];
  List<Law> _filtered = [];
  final TextEditingController _filterController = TextEditingController();
  String _selectedCategory = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final list = await AppDatabase.instance.getLaws();
    setState(() {
      _laws = list;
      _filtered = list;
    });
  }

  List<String> _categories() {
    final values = ['الكل'];
    values.addAll(_laws.map((e) => e.category).toSet());
    return values;
  }

  void _applyFilter() {
    final q = _filterController.text.trim();
    final next = _laws.where((law) {
      final categoryPass = _selectedCategory == 'الكل' || law.category == _selectedCategory;
      final textPass = q.isEmpty || law.name.contains(q) || law.summary.contains(q);
      return categoryPass && textPass;
    }).toList();
    setState(() => _filtered = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('القوانين اليمنية')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _filterController,
              onChanged: (_) => _applyFilter(),
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: 'ابحث داخل القوانين',
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories().map((category) {
                  final selected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                      _applyFilter();
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final law = _filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(law.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${law.category} • ${law.summary}'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () async {
                        final articles = await AppDatabase.instance.getArticlesByLaw(law.id);
                        if (!mounted) return;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LawDetailScreen(
                              lawId: law.id,
                              articleId: articles.isNotEmpty ? articles.first.id : 0,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LawDetailScreen extends StatefulWidget {
  final int lawId;
  final int articleId;

  const LawDetailScreen({super.key, required this.lawId, required this.articleId});

  @override
  State<LawDetailScreen> createState() => _LawDetailScreenState();
}

class _LawDetailScreenState extends State<LawDetailScreen> {
  List<Article> _articles = [];
  int _currentIndex = 0;
  double _fontScale = 1.0;
  bool _isFavorite = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final articles = await AppDatabase.instance.getArticlesByLaw(widget.lawId);
    if (articles.isEmpty) return;
    final idx = articles.indexWhere((e) => e.id == widget.articleId);
    final currentIndex = idx >= 0 ? idx : 0;
    final favorite = await AppDatabase.instance.isFavorite(articles[currentIndex].id);
    setState(() {
      _articles = articles;
      _currentIndex = currentIndex;
      _isFavorite = favorite;
    });
    await AppDatabase.instance.recordRead(widget.lawId, articles[currentIndex].id);
  }

  Article get article => _articles[_currentIndex];

  Future<void> _copyArticle() async {
    final text = 'المادة ${article.articleNumber}\n${article.body}';
    await Clipboard.setData(ClipboardData(text: text));
    Fluttertoast.showToast(msg: 'تم نسخ المادة بنجاح');
  }

  Future<void> _shareArticle() async {
    final text = 'قوانين اليمن\nالمادة ${article.articleNumber}\n${article.body}';
    await Share.share(text);
  }

  Future<void> _toggleFavorite() async {
    await AppDatabase.instance.toggleFavorite(article.id, widget.lawId);
    final favorite = await AppDatabase.instance.isFavorite(article.id);
    setState(() => _isFavorite = favorite);
  }

  Future<void> _addNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    await AppDatabase.instance.addNote(text);
    _noteController.clear();
    Fluttertoast.showToast(msg: 'تم حفظ الملاحظة');
  }

  @override
  Widget build(BuildContext context) {
    if (_articles.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(article.chapter),
        actions: [
          IconButton(onPressed: _copyArticle, icon: const Icon(Icons.copy)),
          IconButton(onPressed: _shareArticle, icon: const Icon(Icons.share)),
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المادة ${article.articleNumber}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppTheme.gold),
            ),
            const SizedBox(height: 8),
            Text('الباب: ${article.chapter}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('الفصل: ${article.section}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Text(
              article.body,
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 18 * _fontScale, height: 1.9, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                  icon: const Icon(Icons.arrow_back_ios_new),
                  label: const Text('السابق'),
                ),
                ElevatedButton.icon(
                  onPressed: _currentIndex < _articles.length - 1 ? () => setState(() => _currentIndex++) : null,
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  label: const Text('التالي'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _fontScale = (_fontScale - 0.1).clamp(0.9, 1.6)),
                  icon: const Icon(Icons.text_decrease),
                ),
                const SizedBox(width: 8),
                Text('A-${_fontScale.toStringAsFixed(1)}'),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _fontScale = (_fontScale + 0.1).clamp(0.9, 1.6)),
                  icon: const Icon(Icons.text_increase),
                ),
                const SizedBox(width: 8),
                Text('A+'),
              ],
            ),
            const SizedBox(height: 18),
            Slider(
              value: _fontScale,
              min: 0.9,
              max: 1.6,
              divisions: 14,
              label: _fontScale.toStringAsFixed(1),
              onChanged: (value) => setState(() => _fontScale = value),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLines: 4,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'إضافة ملاحظة',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _addNote,
              icon: const Icon(Icons.note_add),
              label: const Text('إضافة ملاحظة'),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Article> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favs = await AppDatabase.instance.getFavorites();
    setState(() => _items = favs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المفضلة')),
      body: _items.isEmpty
          ? const Center(child: Text('لا توجد عناصر محفوظة بعد'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text('المادة ${item.articleNumber}'),
                  subtitle: Text(item.body),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => LawDetailScreen(lawId: item.lawId, articleId: item.id)),
                  ),
                );
              },
            ),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _notes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await AppDatabase.instance.getNotes();
    setState(() => _notes = rows);
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      await AppDatabase.instance.addNote(text);
      _controller.clear();
      await _load();
      Fluttertoast.showToast(msg: 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال ثم المحاولة مرة أخرى.');
      return;
    }
    await AppDatabase.instance.addNote(text);
    _controller.clear();
    await _load();
    Fluttertoast.showToast(msg: 'تم إرسال الملاحظة بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ملاحظات واقتراحات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'نسعى إلى تطوير التطبيق باستمرار، وتسهم ملاحظاتكم واقتراحاتكم في تحسين الأداء، وإضافة الميزات الجديدة، وتصحيح أي أخطاء قد تظهر. إذا واجهت مشكلة أو لديك اقتراح، يرجى إرساله، وسيتم مراجعته بعناية في التحديثات القادمة.',
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 5,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: '✍️ مربع لكتابة الملاحظة',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send),
              label: const Text('إرسال'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(note['text'] as String),
                      subtitle: Text(note['created_at'] as String),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التواصل والاستشارات القانونية')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.account_balance, size: 64, color: AppTheme.gold),
              SizedBox(height: 12),
              Text('أسامة خالد المقبلي', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('محاماة – استشارات قانونية – تحرير عقود', textAlign: TextAlign.center),
              SizedBox(height: 12),
              Text('للتواصل: 777001515', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const YemenLawApp());
}
