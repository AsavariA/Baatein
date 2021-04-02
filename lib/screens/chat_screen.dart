import 'dart:async';

import 'package:baatein/authentication/authService.dart';
import 'package:baatein/utils/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:baatein/utils/message_model.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String user;
  final String userEmail;

  ChatScreen({this.user, this.userEmail});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  _chatBubble(
      UserCredentials authUser, Message message, bool isMe, bool isSameUser) {
    if (isMe) {
      return Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topRight,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80,
              ),
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                // color: Theme.of(context).primaryColor,
                color: Color(0xFFFEEFEC),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    message.time,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: <Widget>[
          Container(
            alignment: Alignment.topLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.80,
              ),
              padding: EdgeInsets.all(10),
              margin: EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    message.time,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  _sendMessageArea(UserCredentials authUser) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      height: 70,
      color: Colors.white,
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo),
            iconSize: 25,
            color: Theme.of(context).primaryColor,
            onPressed: () {},
          ),
          Expanded(
            child: TextField(
              onTap: () {
                Timer(
                    Duration(milliseconds: 300),
                    () => _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent));
              },

              minLines: 1, //Normal textInputField will be displayed
              maxLines: 7,
              controller: messageController,
              decoration: InputDecoration.collapsed(
                hintText: 'Send a message...',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            iconSize: 25,
            color: Theme.of(context).primaryColor,
            onPressed: () async {
              var message = messageController.text.trim();
              setState(() {
                messageController.clear();
              });
              Timer(
                  Duration(milliseconds: 500),
                  () => _scrollController
                      .jumpTo(_scrollController.position.maxScrollExtent));
              if (message != "") {
                await FirebaseFirestore.instance
                    .collection("Users")
                    .doc(authUser.email)
                    .collection("Chats")
                    .doc(widget.userEmail)
                    .update({
                  "chats": FieldValue.arrayUnion(
                    [
                      {
                        "message": message,
                        "sender": authUser.email,
                        "timestamp": DateTime.now(),
                      }
                    ],
                  ),
                });
                await FirebaseFirestore.instance
                    .collection("Users")
                    .doc(widget.userEmail)
                    .collection("Chats")
                    .doc(authUser.email)
                    .update({
                  "chats": FieldValue.arrayUnion([
                    {
                      "message": message,
                      "sender": authUser.email,
                      "timestamp": DateTime.now(),
                    }
                  ])
                });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Provider.of<AuthService>(context).currentUser();
    String prevUserId;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          brightness: Brightness.dark,
          centerTitle: true,
          title: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: widget.user,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              color: Colors.white,
              onPressed: () {
                Navigator.pop(context);
              }),
        ),
        body: Column(
          children: <Widget>[
            StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection("Users")
                    .doc(authUser.email)
                    .collection("Chats")
                    .doc(widget.userEmail)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var docRef = snapshot.data;
                    var messages = docRef["chats"];
                    return Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(20),
                        itemCount: messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          var timestamp =
                              messages[index]["timestamp"].toDate().toString();
                          final DateTime docDateTime =
                              DateTime.parse(timestamp);
                          var time =
                              DateFormat("dd MMM HH:mm").format(docDateTime);
                          final Message message = Message(
                              sender: messages[index]["sender"],
                              text: messages[index]["message"],
                              time: time,
                              unread: false);
                          final bool isMe =
                              messages[index]["sender"] == authUser.email;
                          final bool isSameUser =
                              prevUserId == messages[index]["sender"];
                          prevUserId = messages[index]["sender"];
                          return _chatBubble(
                              authUser, message, isMe, isSameUser);
                        },
                      ),
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }),
            _sendMessageArea(authUser),
          ],
        ),
      ),
    );
  }
}
