import 'dart:io';

import 'package:chat_app/models/chat.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/models/user_profile.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:chat_app/services/database_service.dart';
import 'package:chat_app/services/media_service.dart';
import 'package:chat_app/services/storage_service.dart';
import 'package:chat_app/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ChatPage extends StatefulWidget {
  final UserProfile chatUser;

  const ChatPage({super.key, required this.chatUser});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final GetIt _getIt = GetIt.instance;

  late AuthService _authService;
  late DatabaseService _databaseService;
  late MediaService _mediaService;
  late StorageService _storageService;

  ChatUser? currentUser, otherUser;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    currentUser = ChatUser(
      id: _authService.user!.uid,
      firstName: _authService.user!.displayName,
    );
    otherUser = ChatUser(
      id: widget.chatUser.uid!,
      firstName: widget.chatUser.name,
      profileImage: widget.chatUser.pfpURL,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chatUser.name!,
        ),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return StreamBuilder<DocumentSnapshot<Chat>>(
      stream: _databaseService.getChatData(currentUser!.id, otherUser!.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        Chat? chat = snapshot.data?.data();
        List<ChatMessage> messages = [];
        if (chat != null && chat.messages != null) {
          messages = _generateChatMessagesList(chat.messages!);
        }
        return DashChat(
          messageOptions: const MessageOptions(
            showOtherUsersAvatar: true,
            showTime: true,
          ),
          inputOptions: InputOptions(
            alwaysShowSend: true,
            trailing: [
              _mediaMessageButton(), // This should handle image selection
            ],
          ),
          currentUser: currentUser!,
          onSend: _sendMessage,
          messages:
              messages, // Make sure this contains the properly constructed ChatMessages
        );
      },
    );
  }

  Future<void> _sendMessage(ChatMessage chatMessage) async {
    Message message;

    if (chatMessage.medias?.isNotEmpty ?? false) {
      if (chatMessage.medias!.first.type == MediaType.image) {
        // Ensure this is handled correctly
        message = Message(
          senderID: chatMessage.user.id,
          content:
              chatMessage.medias!.first.url, // This should be the image URL
          messageType: MessageType.Image,
          sentAt: Timestamp.fromDate(chatMessage.createdAt),
        );
        await _databaseService.sendChatMessage(
          currentUser!.id,
          otherUser!.id,
          message,
        );
      }
    } else {
      message = Message(
        senderID: currentUser!.id,
        content: chatMessage.text,
        messageType: MessageType.Text,
        sentAt: Timestamp.fromDate(chatMessage.createdAt),
      );
      await _databaseService.sendChatMessage(
        currentUser!.id,
        otherUser!.id,
        message,
      );
    }
  }

  List<ChatMessage> _generateChatMessagesList(List<Message> messages) {
    List<ChatMessage> chatMessages = messages.map((m) {
      if (m.messageType == MessageType.Image) {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          createdAt: m.sentAt!.toDate(),
          medias: [
            ChatMedia(
              url: m.content!, // Ensure this URL is valid
              fileName: "",
              type: MediaType.image,
            ),
          ],
        );
      } else {
        return ChatMessage(
          user: m.senderID == currentUser!.id ? currentUser! : otherUser!,
          text: m.content!,
          createdAt: m.sentAt!.toDate(),
        );
      }
    }).toList();

    // Sort messages by creation date
    chatMessages.sort((a, b) {
      return b.createdAt.compareTo(a.createdAt); // Ascending order
    });
    return chatMessages;
  }

  Widget _mediaMessageButton() {
    return IconButton(
      onPressed: () async {
        File? file = await _mediaService.getImageFromGallery();
        if (file != null) {
          String chatID = generateChatID(
            uid1: currentUser!.id,
            uid2: otherUser!.id,
          );
          String? downloadURL = await _storageService.uploadImageToChat(
              file: file, chatID: chatID);
          if (downloadURL != null) {
            ChatMessage chatMessage = ChatMessage(
                user: currentUser!,
                createdAt: DateTime.now(),
                medias: [
                  ChatMedia(
                    url: downloadURL,
                    fileName: "",
                    type: MediaType.image,
                  )
                ]);
            _sendMessage(chatMessage);
          }
        }
      },
      icon: Icon(
        Icons.image,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
