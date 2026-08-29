// mobile_app/lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../widgets/content_card.dart';
import '../widgets/share_button.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Content> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.length < 2) {
      setState(() {
        _errorMessage = 'يرجى إدخال على الأقل حرفين للبحث';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final results = await apiService.search(query);
      
      setState(() {
        _results = results;
        _isLoading = false;
        if (_results.isEmpty) {
          _errorMessage = 'لم يتم العثور على نتائج لـ "$query"';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في البحث، حاول مرة أخرى';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 ابحث عن الكوميكس'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // شريط البحث
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن أفيش، نكتة، أو كوميكس...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('بحث'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // عرض النتائج أو رسائل الحالة
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _results.isEmpty
                          ? const Center(
                              child: Text('🔍 ابحث عن شيء مضحك!'),
                            )
                          : ListView.builder(
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final content = _results[index];
                                return ContentCard(
                                  content: content,
                                  onShare: (platform) async {
                                    await context.read<ApiService>().shareContent(
                                          contentId: content.id,
                                          platform: platform,
                                        );
                                  },
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