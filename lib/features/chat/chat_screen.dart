import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/responsive_layout.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/cloudinary_service.dart';
import 'package:intl/intl.dart';
import '../../models/admin_post_model.dart';

class ChatScreen extends StatefulWidget {
  final String? otherUserId;
  final AdminPostModel? property;
  const ChatScreen({super.key, this.otherUserId, this.property});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _chatId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChat().then((_) {
      if (widget.property != null) {
        _sendPropertyInquiryOnce();
      }
    });
  }

  void _sendPropertyInquiryOnce() async {
    final user = _auth.currentUser;
    if (user == null || _chatId == null) return;
    
    // Check if we already sent an inquiry for this property in the last few messages
    // (To avoid spamming on every open)
    // For now, let's just send it once as per the user's request.
    final introText = "I'm interested in: ${widget.property!.title} (Ref: ${widget.property!.id})\nPrice: ₹${widget.property!.price}";
    
    final messageId = FirebaseFirestore.instance.collection('chats').doc().id;
    final message = MessageModel(
      id: messageId,
      senderId: user.uid,
      receiverId: widget.otherUserId ?? 'admin',
      text: introText,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Only send if the user is not the admin (clients send to broker)
    final userRole = await AuthService().getUserRole();
    if (userRole != 'admin') {
      await _chatService.sendMessage(_chatId!, message);
    }
  }

  Future<void> _initChat() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final otherId = widget.otherUserId ?? 'admin';
        final chatId = await _chatService.createChat(
          otherId == 'admin' ? user.uid : otherId,
          'admin',
        );
        if (mounted) {
          setState(() {
            _chatId = chatId;
            _isLoading = false;
          });
          // Mark as read
          _chatService.markAsRead(chatId, user.uid);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to initialize chat environment'),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null && _chatId != null) {
      final user = _auth.currentUser;
      if (user == null) return;

      setState(() => _isLoading = true);
      try {
        final cloudinaryService = CloudinaryService();
        final url = await cloudinaryService.uploadImage(File(image.path));
        
        if (url != null) {
          final otherId = widget.otherUserId ?? 'admin';
          final messageId = FirebaseFirestore.instance.collection('chats').doc().id;
          final message = MessageModel(
            id: messageId,
            senderId: user.uid,
            receiverId: otherId,
            text: '',
            timestamp: DateTime.now(),
            isRead: false,
            mediaUrl: url,
          );
          await _chatService.sendMessage(_chatId!, message);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send image')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatId == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    _messageController.clear();

    final otherId = widget.otherUserId ?? 'admin';
    final messageId = FirebaseFirestore.instance.collection('chats').doc().id;
    final message = MessageModel(
      id: messageId,
      senderId: user.uid,
      receiverId: otherId,
      text: text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    try {
      await _chatService.sendMessage(_chatId!, message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to send message')));
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showMessageInfo(MessageModel message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Message Info',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(
              Icons.done_rounded,
              'Sent',
              DateFormat('MMM d, yyyy • h:mm a').format(message.timestamp),
              Colors.grey,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.done_all_rounded,
              'Read',
              message.isRead ? 'Seen by receiver' : 'Not seen yet',
              message.isRead ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to use chat.')));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        leadingWidth: 40,
        leading: widget.otherUserId != null ? IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => context.pop(),
        ) : null,
        title: FutureBuilder<UserModel?>(
          future: widget.otherUserId != null 
              ? AuthService().getUserById(widget.otherUserId!)
              : Future.value(null),
          builder: (context, snapshot) {
            final displayName = widget.otherUserId == null 
                ? 'DealEstate Broker' 
                : (snapshot.data?.name ?? (snapshot.connectionState == ConnectionState.waiting ? 'Loading...' : 'Client Chat'));
            
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF1754CF).withValues(alpha: 0.1),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Color(0xFF1754CF), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white : Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: ResponsiveLayout(
        maxWidth: 800,
        child: Column(
          children: [
            if (widget.property != null) _buildPropertyContext(isDark),
            Expanded(
              child: _chatId == null
                  ? const Center(child: Text('Ready to chat!'))
                  : StreamBuilder<List<MessageModel>>(
                      stream: _chatService.getMessagesStream(_chatId!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final messages = snapshot.data ?? [];

                        if (messages.isEmpty) {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet.\nStart the conversation!',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[400], fontSize: 15),
                              ),
                            ],
                          );
                        }

                        return ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isUser = message.senderId == user.uid;

                            // Mark as delivered if not already (receivers only)
                            if (!isUser && !message.isDelivered && _chatId != null) {
                              _chatService.markAsDelivered(_chatId!, user.uid);
                            }

                            // Mark as Read if not already (receivers only)
                            if (!isUser && !message.isRead && _chatId != null) {
                              _chatService.markAsRead(_chatId!, user.uid);
                            }

                            // Date separator logic
                            bool showDate = false;
                            if (index == messages.length - 1) {
                              showDate = true;
                            } else {
                              final prevMessage = messages[index + 1];
                              if (message.timestamp.day != prevMessage.timestamp.day ||
                                  message.timestamp.month != prevMessage.timestamp.month ||
                                  message.timestamp.year != prevMessage.timestamp.year) {
                                showDate = true;
                              }
                            }

                            return Column(
                              children: [
                                if (showDate) _buildDateHeader(message.timestamp, isDark),
                                ChatBubble(
                                  text: message.text,
                                  isUser: isUser,
                                  timestamp: message.timestamp,
                                  isRead: message.isRead,
                                  isDelivered: message.isDelivered,
                                  mediaUrl: message.mediaUrl,
                                  onLongPress: isUser ? () => _showMessageInfo(message) : null,
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
            ),
            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.attach_file_rounded, color: Colors.grey[400]),
                            onPressed: _pickAndSendImage,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 48,
                    width: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1754CF), Color(0xFF64B5F6)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, bool isDark) {
    String formattedDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      formattedDate = "Today";
    } else if (checkDate == yesterday) {
      formattedDate = "Yesterday";
    } else {
      formattedDate = DateFormat('MMMM d, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        formattedDate,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPropertyContext(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 48,
              width: 48,
              color: Colors.grey[200],
              child: widget.property!.mediaUrls.isNotEmpty
                  ? Image.network(widget.property!.mediaUrls.first, fit: BoxFit.cover)
                  : const Icon(Icons.home, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.property!.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${widget.property!.price} • ${widget.property!.location}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            widget.property!.transactionType.toUpperCase(),
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w900, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
