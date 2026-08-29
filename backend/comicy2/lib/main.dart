import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'كوميكس دايلي',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<dynamic> _content = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ⚠️ استبدل 192.168.1.100 بعنوان IP الخاص بجهازك
  final String _baseUrl = 'http://192.168.1.100:3000';

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/content'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _content = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '❌ فشل في تحميل المحتوى';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '❌ خطأ في الاتصال بالخادم';
        _isLoading = false;
      });
    }
  }

  void _shareContent(String title) async {
    final String text = '😂 ${title}\n\nشاركنا الضحك مع تطبيق كوميكس دايلي!';
    final String url = 'https://api.whatsapp.com/send?text=${Uri.encodeComponent(text)}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ لا يمكن فتح واتساب')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('كوميكس دايلي'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ContentSearchDelegate(_baseUrl),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchContent,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red),
                      SizedBox(height: 16),
                      Text(_errorMessage!, style: TextStyle(fontSize: 18)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchContent,
                        child: Text('حاول مرة أخرى'),
                      ),
                    ],
                  ),
                )
              : _content.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('⚠️ لا يوجد محتوى حالياً'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: _content.length,
                      itemBuilder: (context, index) {
                        final item = _content[index];
                        return _buildContentCard(item);
                      },
                    ),
    );
  }

  Widget _buildContentCard(dynamic item) {
    final isVideo = item['type'] == 'video';
    final imageUrl = '$_baseUrl${item['filePath']}';

    return Card(
      margin: EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            child: isVideo
                ? Container(
                    height: 220,
                    color: Colors.black,
                    child: Center(
                      child: Icon(Icons.play_circle_filled, size: 80, color: Colors.white.withOpacity(0.8)),
                    ),
                  )
                : Image.network(
                    imageUrl,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 250,
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('⚠️ لا يمكن تحميل الصورة'),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'بدون عنوان',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                SizedBox(height: 8),
                Text(
                  item['description'] ?? '',
                  style: TextStyle(color: Colors.grey[700], fontSize: 15),
                ),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: (item['tags'] as List? ?? [])
                      .map<Widget>((tag) => Chip(
                            label: Text('#$tag', style: TextStyle(fontSize: 12)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.deepPurple.shade50,
                            side: BorderSide.none,
                          ))
                      .toList(),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildShareButton('واتساب', Colors.green, Icons.chat, () {
                      _shareContent(item['title']);
                    }),
                    _buildShareButton('ماسنجر', Colors.blue, Icons.message, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('🔜 ميزة الماسنجر قريباً!')),
                      );
                    }),
                    _buildShareButton('فيسبوك', Colors.indigo, Icons.facebook, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('🔜 ميزة فيسبوك قريباً!')),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton(String label, Color color, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }
}

// ====== شاشة البحث ======
class ContentSearchDelegate extends SearchDelegate<String> {
  final String baseUrl;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  ContentSearchDelegate(this.baseUrl);

  @override
  String get searchFieldLabel => 'ابحث عن نكتة، أفيش، أو كوميكس...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          _searchResults = [];
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('ابحث عن نكتة أو كوميكس', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    _performSearch();
    return _buildSearchResults();
  }

  void _performSearch() {
    if (_isSearching) return;
    _isSearching = true;
    http.get(Uri.parse('$baseUrl/api/search?q=$query')).then((response) {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _searchResults = data['data'] ?? [];
      } else {
        _searchResults = [];
      }
      _isSearching = false;
    }).catchError((e) {
      _searchResults = [];
      _isSearching = false;
    });
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty && query.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('لا توجد نتائج لـ "$query"', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return ListTile(
          leading: Icon(
            item['type'] == 'video' ? Icons.video_library : Icons.image,
            color: Colors.deepPurple,
          ),
          title: Text(item['title'] ?? 'بدون عنوان'),
          subtitle: Text(item['description'] ?? ''),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            close(context, '');
          },
        );
      },
    );
  }
}