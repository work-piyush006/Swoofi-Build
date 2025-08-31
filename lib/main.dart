import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EducationPortal());
}

class EducationPortal extends StatelessWidget {
  const EducationPortal({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Education Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}

/// ====================== SPLASH ======================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.menu_book_rounded, size: 96, color: Colors.indigo),
          const SizedBox(height: 16),
          Text('Education Portal',
              style: GoogleFonts.poppins(
                  fontSize: 28, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('All Notes at One Place',
              style: GoogleFonts.poppins(fontSize: 14)),
        ]),
      ),
    );
  }
}

/// ====================== STORAGE KEYS & HELPERS ======================
class StorageKeys {
  static const class11 = 'class11_files';
  static const class12 = 'class12_files';
  static const dpp = 'dpp_files';
  static const reviews = 'reviews'; // list of strings: name|stars|text
  static const quotes = 'quotes';   // list of strings
  static const phone = 'phone';
  static const email = 'email';
  static const url1 = 'url1';
  static const url2 = 'url2';
  static const website = 'website';
}

Future<Directory> _appDocsDir() async => getApplicationDocumentsDirectory();

Future<List<String>> _getList(String key) async {
  final p = await SharedPreferences.getInstance();
  return p.getStringList(key) ?? [];
}
Future<void> _setList(String key, List<String> value) async {
  final p = await SharedPreferences.getInstance();
  await p.setStringList(key, value);
}
Future<void> _setString(String key, String value) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(key, value);
}
Future<String> _getString(String key, {String def = ''}) async {
  final p = await SharedPreferences.getInstance();
  return p.getString(key) ?? def;
}

/// ====================== HOME ======================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  // Auto sliders
  final PageController _quotesCtrl = PageController();
  final PageController _reviewsCtrl = PageController();
  Timer? _quotesTimer;
  Timer? _reviewsTimer;

  // Data
  List<String> _quotes = [
    "Success comes to those who work hard.",
    "Consistency is the key to mastery.",
    "Never stop learning.",
    "Discipline beats motivation.",
    "Small steps lead to big achievements."
  ];
  List<Review> _reviews = [];
  String phone = '';
  String email = '';
  String url1 = '';
  String url2 = '';
  String website = 'https://kulbhushan.freevar.com';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _quotesTimer?.cancel();
    _reviewsTimer?.cancel();
    _quotesCtrl.dispose();
    _reviewsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    // quotes
    final savedQuotes = await _getList(StorageKeys.quotes);
    if (savedQuotes.isNotEmpty) _quotes = savedQuotes;

    // reviews
    final rawReviews = await _getList(StorageKeys.reviews);
    _reviews = rawReviews.map(Review.fromStorage).toList();

    // contacts & website
    phone = await _getString(StorageKeys.phone, def: '');
    email = await _getString(StorageKeys.email, def: '');
    url1 = await _getString(StorageKeys.url1, def: '');
    url2 = await _getString(StorageKeys.url2, def: '');
    website = await _getString(StorageKeys.website,
        def: 'https://kulbhushan.freevar.com');

    if (mounted) setState(() {});
    _startAutoSlides();
  }

  void _startAutoSlides() {
    _quotesTimer?.cancel();
    _quotesTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_quotesCtrl.hasClients || _quotes.isEmpty) return;
      final next = (_quotesCtrl.page?.round() ?? 0) + 1;
      _quotesCtrl.animateToPage(
        next % _quotes.length,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });

    _reviewsTimer?.cancel();
    if (_reviews.isNotEmpty) {
      _reviewsTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!_reviewsCtrl.hasClients || _reviews.isEmpty) return;
        final next = (_reviewsCtrl.page?.round() ?? 0) + 1;
        _reviewsCtrl.animateToPage(
          next % _reviews.length,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _openAdmin() {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Admin Access'),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter 4-digit PIN'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (pinCtrl.text == '4209') {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminPanelScreen()),
                  ).then((_) => _loadAll());
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Incorrect PIN! Please try again.')));
                }
              },
              child: const Text('Enter')),
        ],
      ),
    );
  }

  void _goMainMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  void _openReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsScreen(
          existing: _reviews,
          onAdded: (r) async {
            final list = await _getList(StorageKeys.reviews);
            list.add(r.toStorage());
            await _setList(StorageKeys.reviews, list);
          },
        ),
      ),
    ).then((_) => _loadAll());
  }

  void _openContact() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContactScreen(
          phone: phone,
          email: email,
          url1: url1,
          url2: url2,
        ),
      ),
    );
  }

  void _openWebsite() async {
    final url = Uri.parse(website);
    if (!await canLaunchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Cannot open website. Please check URL.')));
      }
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final description =
        "This app is created for 11th & 12th Computer Science Students.\n"
        "Learn from our notes & practice from DPP.\n"
        "More features coming soon!\n\n"
        "Developed with ❤️ by Kulbhushan Jadeja";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Education Portal'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdmin,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.phone), label: 'Contact'),
          NavigationDestination(icon: Icon(Icons.wifi), label: 'Website'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) _openContact();
          if (i == 2) _openWebsite();
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            children: [
              const SizedBox(height: 8),
              const Icon(Icons.school_rounded, size: 72, color: Colors.indigo),
              const SizedBox(height: 8),
              Text('Education Portal',
                  style: GoogleFonts.poppins(
                      fontSize: 24, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Text(description, textAlign: TextAlign.center),
          const SizedBox(height: 20),

          // Quotes slider (auto)
          Text('Important Message:',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: PageView.builder(
              controller: _quotesCtrl,
              itemCount: _quotes.isEmpty ? 1 : _quotes.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _quotes.isEmpty
                      ? 'Add quotes from Admin (+)'
                      : _quotes[i],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: FilledButton(
              onPressed: _goMainMenu,
              child: const Text('NEXT'),
            ),
          ),

          const SizedBox(height: 20),

          // Reviews slider (always visible)
          Text('What students say',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          if (_reviews.isEmpty)
            Column(
              children: [
                const Text('Be the First to Review us 👇👇'),
                const SizedBox(height: 6),
                FilledButton(
                    onPressed: _openReviews,
                    child: const Text('Review Our App')),
              ],
            )
          else
            SizedBox(
              height: 110,
              child: PageView.builder(
                controller: _reviewsCtrl,
                itemCount: _reviews.length,
                itemBuilder: (_, i) {
                  final r = _reviews[i];
                  return Card(
                    elevation: 0,
                    color: Colors.indigo.withOpacity(.06),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${r.name} • ${'⭐' * r.stars}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(r.text, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// ====================== MAIN MENU ======================
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _openList(BuildContext context, String key, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfListScreen(categoryKey: key, title: title)),
    );
  }

  void _openReviews(BuildContext context) async {
    final raw = await _getList(StorageKeys.reviews);
    final existing = raw.map(Review.fromStorage).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsScreen(
          existing: existing,
          onAdded: (r) async {
            final list = await _getList(StorageKeys.reviews);
            list.add(r.toStorage());
            await _setList(StorageKeys.reviews, list);
          },
        ),
      ),
    );
  }

  void _openContact(BuildContext context) async {
    final phone = await _getString(StorageKeys.phone, def: '');
    final email = await _getString(StorageKeys.email, def: '');
    final url1 = await _getString(StorageKeys.url1, def: '');
    final url2 = await _getString(StorageKeys.url2, def: '');
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              ContactScreen(phone: phone, email: email, url1: url1, url2: url2)),
    );
  }

  void _openWebsite(BuildContext context) async {
    final site =
        await _getString(StorageKeys.website, def: 'https://kulbhushan.freevar.com');
    final url = Uri.parse(site);
    if (!await canLaunchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open website.')));
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _openAdmin(BuildContext context) {
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Admin Access'),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter 4-digit PIN'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                if (pinCtrl.text == '4209') {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminPanelScreen()),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Incorrect PIN! Please try again.')));
                }
              },
              child: const Text('Enter')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Menu'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAdmin(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.phone), label: 'Contact'),
          NavigationDestination(icon: Icon(Icons.wifi), label: 'Website'),
        ],
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 0) Navigator.pop(context);
          if (i == 1) _openContact(context);
          if (i == 2) _openWebsite(context);
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuCard(
            title: 'Class 11 Notes',
            icon: Icons.book_rounded,
            onTap: () =>
                _openList(context, StorageKeys.class11, 'Class 11 Notes'),
          ),
          _menuCard(
            title: 'Class 12 Notes',
            icon: Icons.menu_book_rounded,
            onTap: () =>
                _openList(context, StorageKeys.class12, 'Class 12 Notes'),
          ),
          _menuCard(
            title: 'DPP',
            icon: Icons.article_rounded,
            onTap: () => _openList(context, StorageKeys.dpp, 'DPP'),
          ),
          _menuCard(
            title: 'Reviews',
            icon: Icons.reviews_outlined,
            onTap: () => _openReviews(context),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios_rounded),
        onTap: onTap,
      ),
    );
  }
}

/// ====================== PDF LIST + VIEWER ======================
class PdfListScreen extends StatefulWidget {
  final String categoryKey;
  final String title;
  const PdfListScreen({super.key, required this.categoryKey, required this.title});

  @override
  State<PdfListScreen> createState() => _PdfListScreenState();
}
class _PdfListScreenState extends State<PdfListScreen> {
  List<String> paths = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    paths = await _getList(widget.categoryKey);
    setState(() {});
  }

  void _openPdf(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerScreen(path: path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: paths.isEmpty
          ? const Center(child: Text('Notes/DPP Upload SOON...'))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: paths.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final name = paths[i].split(Platform.pathSeparator).last;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf),
                    title: Text(name),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openPdf(paths[i]),
                  ),
                );
              },
            ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String path; // local file path
  const PdfViewerScreen({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: Builder(builder: (context) {
        try {
          
