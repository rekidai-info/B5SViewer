import 'dart:core';

import 'package:flutter/material.dart';

class PostMessage {
  String from;
  String mail;
  String message;

  PostMessage() {
    this.from = '';
    this.mail = 'sage';
    this.message = '';
  }
}

class AskNewMessage extends ModalRoute<MapEntry<bool, PostMessage>> {
  bool isDark;

  PostMessage initialPostMessage;

  AskNewMessage(this.isDark, this.initialPostMessage);

  @override
  Duration get transitionDuration => Duration(milliseconds: 500);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color get barrierColor =>
      isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85);

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: _buildOverlayContent(context),
      ),
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    PostMessage postMessage = initialPostMessage;
    if (postMessage == null) {
      initialPostMessage = PostMessage();
      postMessage = initialPostMessage;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(height: 50),
          Text('投稿するメッセージを入力してください'),
          Divider(),
          TextField(
            controller: TextEditingController(text: initialPostMessage.from),
            decoration: InputDecoration(labelText: '名前'),
            onChanged: (value) {
              postMessage.from = value;
            },
            maxLines: 1,
          ),
          Divider(),
          TextField(
            controller: TextEditingController(text: initialPostMessage.mail),
            decoration: InputDecoration(labelText: 'メールアドレス'),
            onChanged: (value) {
              postMessage.mail = value;
            },
            maxLines: 1,
          ),
          Divider(),
          Container(
            constraints: BoxConstraints(maxHeight: 230),
            child: Scrollbar(
              child: TextField(
                controller:
                    TextEditingController(text: initialPostMessage.message),
                decoration: InputDecoration(labelText: 'メッセージ'),
                onChanged: (value) {
                  postMessage.message = value;
                },
                maxLines: null,
              ),
            ),
          ),
          Divider(),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.cancel),
                  tooltip: 'キャンセル',
                  onPressed: () => Navigator.of(context)
                      .pop(MapEntry<bool, PostMessage>(false, postMessage)),
                ),
                Text(' '),
                IconButton(
                  icon: const Icon(Icons.message),
                  tooltip: '投稿',
                  onPressed: () => Navigator.of(context)
                      .pop(MapEntry<bool, PostMessage>(true, postMessage)),
                )
              ],
            ),
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }
}
