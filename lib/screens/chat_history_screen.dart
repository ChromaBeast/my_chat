import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:super_ai/common/custom_toast.dart';
import '../controllers/chat_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_session_model.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  String _search = '';

  String formatChatSessionTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24 && now.day == time.day) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (now.difference(time).inDays == 1 ||
        (now.day - time.day == 1 &&
            now.month == time.month &&
            now.year == time.year)) {
      return 'Yesterday, ${DateFormat('h:mm a').format(time)}';
    } else {
      return DateFormat('yMMMd, h:mm a').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search sessions...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 12,
              ),
            ),
            onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                userId == null
                    ? const Stream.empty()
                    : FirebaseFirestore.instance
                        .collection('chat_sessions')
                        .where('userId', isEqualTo: userId)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: colorScheme.primary.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No chat history found.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start a new conversation!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }
              final sessions =
                  snapshot.data!.docs
                      .map((doc) => ChatSessionModel.fromFirestore(doc))
                      .where((session) {
                        final title = session.title.toLowerCase();
                        final messages = session.messages;
                        final snippet =
                            messages.isNotEmpty
                                ? (messages.first.message as dynamic).text
                                        ?.toString()
                                        .toLowerCase() ??
                                    ''
                                : '';
                        return _search.isEmpty ||
                            title.contains(_search) ||
                            snippet.contains(_search);
                      })
                      .toList();
              if (sessions.isEmpty) {
                return Center(child: Text('No sessions match your search.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final title = session.title;
                  final timestamp = session.timestamp;
                  final sessionId = session.id;
                  return Dismissible(
                    key: ValueKey(sessionId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      color: colorScheme.error.withValues(alpha: 0.1),
                      child: Icon(Icons.delete, color: colorScheme.error),
                    ),
                    confirmDismiss: (_) async {
                      return await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Delete Session'),
                              content: const Text(
                                'Are you sure you want to delete this session?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Get.back(result: true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                    },
                    onDismissed: (_) async {
                      await FirebaseFirestore.instance
                          .collection('chat_sessions')
                          .doc(sessionId)
                          .delete();
                      CustomToast.showSuccess('Session deleted');
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: colorScheme.primary,
                          ),
                        ),
                        title: GestureDetector(
                          onTap: () async {
                            final controller = TextEditingController(
                              text: title,
                            );
                            final newTitle = await Get.dialog<String>(
                              AlertDialog(
                                title: const Text('Rename Session'),
                                content: TextField(
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter new title',
                                  ),
                                  controller: controller,
                                  onSubmitted:
                                      (v) => Get.back(result: v.trim()),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Get.back(
                                          result: controller.text.trim(),
                                        ),
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );
                            if (newTitle != null &&
                                newTitle.isNotEmpty &&
                                newTitle != title) {
                              await FirebaseFirestore.instance
                                  .collection('chat_sessions')
                                  .doc(sessionId)
                                  .update({'title': newTitle});
                              CustomToast.showSuccess('Session renamed');
                            }
                          },
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        subtitle: Text(
                          formatChatSessionTime(timestamp),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary.withValues(alpha: 0.7),
                          ),
                        ),
                        onTap: () async {
                          final chatController = Get.find<ChatController>();
                          await chatController.loadSessionFromFirestore(
                            session.toMap(),
                          );
                          Get.back();
                          final tabController = DefaultTabController.of(
                            context,
                          );
                          tabController.animateTo(0);
                                                },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
