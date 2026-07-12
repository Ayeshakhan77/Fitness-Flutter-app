import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../widgets/custom_widgets.dart';
import '../services/api_service.dart';

class FitnessCoachScreen extends StatefulWidget {
  const FitnessCoachScreen({super.key});

  @override
  State<FitnessCoachScreen> createState() => _FitnessCoachScreenState();
}

class _FitnessCoachScreenState extends State<FitnessCoachScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Check if token exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ApiService.getToken();
      print('🔍 Current token in ChatbotScreen: $token');
      if (token == null || token.isEmpty) {
        print('⚠️ No token found! User might not be logged in properly.');
      }
    });
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final provider = Provider.of<ChatbotProvider>(context, listen: false);
    await provider.loadMessagesFromServer();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final message = _messageController.text.trim();
    _messageController.clear();
    
    final provider = Provider.of<ChatbotProvider>(context, listen: false);
    await provider.sendMessageToServer(message);
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Coach'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final provider = Provider.of<ChatbotProvider>(context, listen: false);
              await ApiService.clearChatMessages();
              await provider.loadMessagesFromServer();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat cleared')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatbotProvider>(
              builder: (context, provider, _) {
                if (provider.messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Say hello to your fitness coach!', 
                          style: TextStyle(fontSize: 16)),
                        SizedBox(height: 8),
                        Text('Ask about workouts, nutrition, or motivation',
                          style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final message = provider.messages[index];
                    return ChatBubble(
                      message: message.text,
                      isUser: message.isUser,
                      time: message.timestamp,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _messageController,
                    label: 'Type your message...',
                    icon: Icons.message,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}