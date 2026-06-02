import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isRead;
  final bool isDelivered;
  final String? mediaUrl;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isRead,
    this.isDelivered = false,
    this.mediaUrl,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeStr = DateFormat('h:mm a').format(timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                padding: EdgeInsets.all(mediaUrl != null ? 4 : 10),
                decoration: BoxDecoration(
                  color: isUser 
                      ? const Color(0xFF1754CF) // DealEstate Deep Blue for sent
                      : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF1F4F9)), // Light Grey for received
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 0), // WhatsApp-like tail
                    bottomRight: Radius.circular(isUser ? 0 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (mediaUrl != null) 
                      Padding(
                        padding: const EdgeInsets.all(2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              Image.network(
                                mediaUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 250,
                                    height: 250,
                                    color: isDark ? Colors.white10 : Colors.grey[100],
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
                                  );
                                },
                              ),
                              if (text.isEmpty)
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(timeStr, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                                        if (isUser) ...[
                                          const SizedBox(width: 4),
                                          _buildTicks(),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    if (text.contains('https://dealestate.web.app/property/'))
                      Builder(builder: (context) {
                        final regExp = RegExp(r'https://dealestate\.web\.app/property/([a-zA-Z0-9_-]+)');
                        final match = regExp.firstMatch(text);
                        if (match != null && match.group(1) != null) {
                          final propertyId = match.group(1)!;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4, left: 10, right: 10),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.home_work_rounded, size: 16),
                              label: const Text('View Property', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isUser ? Colors.white : const Color(0xFF1754CF),
                                side: BorderSide(color: isUser ? Colors.white54 : const Color(0xFF1754CF).withAlpha(100)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () {
                                context.push('/property/$propertyId');
                              },
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    if (text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6, bottom: 2, left: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: isUser ? Colors.white.withValues(alpha: 0.7) : Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 4),
                              _buildTicks(),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicks() {
    if (isRead) {
      return const Icon(Icons.done_all_rounded, size: 15, color: Color(0xFF4FC3F7)); // Light Blue/Cyan ticks for Read
    } else if (isDelivered) {
      return const Icon(Icons.done_all_rounded, size: 15, color: Colors.white60);
    } else {
      return const Icon(Icons.done_rounded, size: 15, color: Colors.white60);
    }
  }
}
