import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

import '5ch_api.dart';
import 'message.dart';
import 'message_list.dart';

class PopupMessage extends ModalRoute<void> {
  bool isDark;

  List<Message> messages;

  List<Message> displayMessages;

  PopupMessage(this.isDark, this.messages, this.displayMessages);

  @override
  Duration get transitionDuration => Duration(milliseconds: 200);

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => true;

  @override
  Color get barrierColor => isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.85);

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
        ],
      ),
      body: _buildOverlayContent(context),
    );
  }

  Widget makeMessage(BuildContext context, int index) {
    Message message = displayMessages[index];
    Color noColor;
    Color idColor;
    List<Linkifier> nameLinkifiers = [];

    if (message.responseCount == null || message.responseCount <= 0) {
      noColor = Colors.grey;
    } else if (message.responseCount < 3) {
      noColor = Colors.blue;
    } else {
      noColor = Colors.red;
    }

    if (message.postCount == 1) {
      idColor = Colors.grey;
    } else if (message.postCount < 5) {
      idColor = Colors.blue;
    } else {
      idColor = Colors.red;
    }

    if (message.name.contains('(') && message.name.contains(')')) {
      if (message.name.contains('-')) {
        nameLinkifiers.add(WacchoiLinkifier());
      }
      if (message.name.contains('[') && message.name.contains(']') && message.name.contains('.')) {
        nameLinkifiers.add(IPLinkifier());
      }
    }

    const double scale = 0.85;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SelectableLinkify( // No
              onOpen: (link) {
                Message message = findMessage(messages, int.parse(link.url.trim(), radix: 10));

                Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) {
                    return ConstantMessageListWidget(messages[0].thread, message.responses, messages);
                  },
                ));
              },
              text: '${message.no}',
              textAlign: TextAlign.left,
              linkifiers: [NoLinkifier(message)],
              options: LinkifyOptions(humanize: true),
              style: DefaultTextStyle.of(context).style.apply(color: noColor, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(color: noColor, fontSizeFactor: scale, decoration: TextDecoration.underline),
              maxLines: 1,
            ),
            Flexible(child: SelectableLinkify( // Name
              onOpen: (link) {
                List<Message> messagesByLinkable = [];

                for (message in messages) {
                  if (message.name.toUpperCase().contains(link.url.toUpperCase())) {
                    messagesByLinkable.add(message);
                  }
                }

                Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) {
                    return ConstantMessageListWidget(message.thread, messagesByLinkable, messages);
                  },
                ));
              },
              text: message.name,
              options: LinkifyOptions(humanize: true),
              style: DefaultTextStyle.of(context).style.apply(color: Colors.green, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(color: Colors.green, fontSizeFactor: scale, decoration: TextDecoration.underline),
              linkifiers: nameLinkifiers,
              maxLines: null,
            )),
            SelectableLinkify( // Address
              onOpen: (link) {},
              text: message.address,
              options: LinkifyOptions(humanize: true),
              style: DefaultTextStyle.of(context).style.apply(color: Colors.grey, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(color: Colors.grey, fontSizeFactor: scale, decoration: TextDecoration.underline),
              linkifiers: [],
              maxLines: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SelectableLinkify( // Date
              onOpen: (link) {},
              text: message.date,
              options: LinkifyOptions(humanize: true),
              style: DefaultTextStyle.of(context).style.apply(color: Colors.grey, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(color: Colors.grey, fontSizeFactor: scale, decoration: TextDecoration.underline),
              linkifiers: [],
              maxLines: 1,
            ),
            SelectableLinkify( // ID prefix
              onOpen: (link) {},
              text: 'ID(${message.postNo}/${message.postCount})',
              linkifiers: [],
              style: DefaultTextStyle.of(context).style.apply(color: idColor, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(color: idColor, fontSizeFactor: scale, decoration: TextDecoration.underline),
              maxLines: 1,
            ),
            SelectableLinkify( // ID prefix
              onOpen: (link) {},
              text: ':',
              linkifiers: [],
              style: DefaultTextStyle.of(context).style.apply(color: Colors.grey, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(color: Colors.grey, fontSizeFactor: scale, decoration: TextDecoration.underline),
              maxLines: 1,
            ),
            SelectableLinkify( // ID
              onOpen: (link) {
                List<Message> messagesById = [];

                for (message in messages) {
                  if (message.id == link.url) {
                    messagesById.add(message);
                  }
                }

                Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) {
                    return ConstantMessageListWidget(message.thread, messagesById, messages);
                  },
                ));
              },
              text: message.id,
              linkifiers: [IdLinkifier()],
              style: DefaultTextStyle.of(context).style.apply(color: idColor, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(color: idColor, fontSizeFactor: scale, decoration: TextDecoration.underline),
              maxLines: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: SelectableLinkify( // Message
                onOpen: (link) {
                  if (link.url.startsWith('>>')) {
                    if (link.url.contains('-')) {
                      final split = link.url.substring('>>'.length).split('-');

                      int begin = int.parse(split[0].trim(), radix: 10);
                      int end = int.parse(split[1].trim(), radix: 10);

                      if (begin > end) {
                        final tmp = begin;
                        begin = end;
                        end = tmp;
                      }

                      List<Message> messages = [];

                      for (int i = begin; i <= end; ++i) {
                        Message message = findMessage(messages, i);

                        if (message != null) {
                          messages.add(message);
                        }
                      }

                      Navigator.of(context).push(PopupMessage(isDark, messages, messages));
                    } else {
                      Message message = findMessage(messages, int.parse(link.url.substring(2), radix: 10));

                      if (message != null) {
                        Navigator.of(context).push(PopupMessage(isDark, messages, [message]));
                      }
                    }
                  } else {
                    launch(link.url);
                  }
                },
                text: message.text,
                options: LinkifyOptions(humanize: true),
                linkifiers: [UrlLinkifier(), AnchorLinkifier()],
              ),
            ),
          ],
        ),
      ],
    );

    return ListTile(
      title: title,
    );
  }

  Widget _buildOverlayContent(BuildContext context) {
    return Scrollbar(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: displayMessages.length,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              makeMessage(context, index),
              Divider(height: 2),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: animation,
        child: child,
      ),
    );
  }
}