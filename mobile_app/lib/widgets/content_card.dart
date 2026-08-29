// mobile_app/lib/widgets/content_card.dart
import 'package:flutter/material.dart';
import '../models/content.dart';
import 'share_button.dart';

class ContentCard extends StatelessWidget {
  final Content content;
  final Function(String platform) onShare;

  const ContentCard({
    Key? key,
    required this.content,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عرض المحتوى بناءً على النوع
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: content.type == ContentType.image
                ? Image.network(
                    content.fileUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.error)),
                      );
                    },
                  )
                : content.type == ContentType.video
                    ? Container(
                        height: 200,
                        color: Colors.black,
                        child: Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            size: 64,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      )
                    : Container(
                        height: 200,
                        color: Colors.deepPurple[50],
                        child: Center(
                          child: Icon(
                            Icons.audio_file,
                            size: 64,
                            color: Colors.deepPurple[300],
                          ),
                        ),
                      ),
          ),
          
          // وصف المحتوى وأزرار المشاركة
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  content.description ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // علامات تصنيف المحتوى
                Wrap(
                  spacing: 8,
                  children: content.tags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      labelStyle: const TextStyle(fontSize: 12),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 12),
                
                // أزرار المشاركة
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ShareButton(
                      platform: 'whatsapp',
                      icon: Icons.chat,
                      label: 'واتساب',
                      color: Colors.green,
                      onPressed: () => onShare('whatsapp'),
                    ),
                    ShareButton(
                      platform: 'messenger',
                      icon: Icons.message,
                      label: 'ماسنجر',
                      color: Colors.blue,
                      onPressed: () => onShare('messenger'),
                    ),
                    ShareButton(
                      platform: 'facebook',
                      icon: Icons.facebook,
                      label: 'فيسبوك',
                      color: Colors.indigo,
                      onPressed: () => onShare('facebook'),
                    ),
                    ShareButton(
                      platform: 'twitter',
                      icon: Icons.bolt,
                      label: 'إكس',
                      color: Colors.black,
                      onPressed: () => onShare('twitter'),
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