import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '5ch_api.dart';
import 'ask_new_message.dart';
import 'message.dart';
import 'popup_message.dart';
import 'preferences.dart';
import 'thread.dart';

class MessageListWidget extends StatefulWidget {
  final Thread thread;

  const MessageListWidget(this.thread, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MessageListState();
  }
}

class MessageListState extends State<MessageListWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(debugLabel: 'MessageListState');
  ItemScrollController itemScrollController = ItemScrollController();
  ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  bool disableRefresh;
  bool loading;
  List<Message> messages;
  PostMessage initialPostMessage;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    disableRefresh = false;
    loading = false;
    messages = [];
    if (initialPostMessage == null) {
      initialPostMessage = PostMessage();
    }
    getMessages();
  }

  @override
  @protected
  @mustCallSuper
  void dispose() {
    saveThreadScrollIndex();

    super.dispose();
  }

  void saveThreadScrollIndex() {
    var scrollIndex = 0;
    var scrollIndexLeading = 0.0;
    for (var value in itemPositionsListener.itemPositions.value) {
      if (value.index > scrollIndex) {
        scrollIndex = value.index;
        scrollIndexLeading = value.itemLeadingEdge;
        break;
      }
    }

    SharedPreferences.getInstance().then((prefs) {
      Preferences.setThreadScrollIndex(prefs, widget.thread.dat, scrollIndex);
      Preferences.setThreadScrollIndexLeading(
          prefs, widget.thread.dat, scrollIndexLeading);
    });
  }

  void getMessages() {
    if (disableRefresh) {
      return;
    }

    if (this.mounted) {
      setState(() {
        this.loading = true;
      });
    } else {
      return;
    }

    SharedPreferences.getInstance().then((prefs) {
      auth(widget.thread).then((sid) {
        var prevScrollIndex = 0;
        var prevScrollIndexLeading = 0.0;
        if (messages.isEmpty) {
          // 初回表示
          prevScrollIndex =
              Preferences.getThreadScrollIndex(prefs, widget.thread.dat);
          prevScrollIndexLeading =
              Preferences.getThreadScrollIndexLeading(prefs, widget.thread.dat);
        } else {
          // リロードアイコンからリロードした場合
          if (itemPositionsListener.itemPositions.value.isNotEmpty) {
            prevScrollIndex =
                itemPositionsListener.itemPositions.value.first.index;
            prevScrollIndexLeading =
                itemPositionsListener.itemPositions.value.first.itemLeadingEdge;
          }
        }

        dat(widget.thread, sid).then((messages) {
          if (messages == null) {
            messages = [];
          }

          final List<RegExp> ngIdsRegex = [];
          final List<RegExp> ngNamesRegex = [];
          final List<RegExp> ngWordsRegex = [];

          for (String ngIdRegex in Preferences.getNGIdsRegex(prefs)) {
            try {
              ngIdsRegex.add(
                  RegExp(ngIdRegex, multiLine: false, caseSensitive: false));
            } catch (e) {
              ScaffoldMessenger.of(_scaffoldKey.currentContext)
                  .showSnackBar(SnackBar(
                duration: Duration(milliseconds: 3000),
                content: Text(e.toString()),
              ));
            }
          }
          for (String ngNameRegex in Preferences.getNGNamesRegex(prefs)) {
            try {
              ngNamesRegex.add(
                  RegExp(ngNameRegex, multiLine: false, caseSensitive: false));
            } catch (e) {
              ScaffoldMessenger.of(_scaffoldKey.currentContext)
                  .showSnackBar(SnackBar(
                duration: Duration(milliseconds: 3000),
                content: Text(e.toString()),
              ));
            }
          }
          for (String ngWordRegex in Preferences.getNGWordsRegex(prefs)) {
            try {
              ngWordsRegex.add(
                  RegExp(ngWordRegex, multiLine: true, caseSensitive: false));
            } catch (e) {
              ScaffoldMessenger.of(_scaffoldKey.currentContext)
                  .showSnackBar(SnackBar(
                duration: Duration(milliseconds: 3000),
                content: Text(e.toString()),
              ));
            }
          }

          for (int i = 0; i < messages.length; ++i) {
            // NG
            bool remove = false;

            if (Preferences.ngIds.contains(messages[i].id)) {
              // NG ID
              remove = true;
            }
            if (!remove) {
              for (String ngName in Preferences.ngNames) {
                // NG Name
                if (messages[i]
                    .name
                    .toUpperCase()
                    .contains(ngName.toUpperCase())) {
                  remove = true;
                  break;
                }
              }
            }
            if (!remove) {
              for (String ngWord in Preferences.ngWords) {
                // NG Word
                if (messages[i]
                    .text
                    .toUpperCase()
                    .contains(ngWord.toUpperCase())) {
                  remove = true;
                  break;
                }
              }
            }

            if (!remove) {
              for (RegExp ngIdRegex in ngIdsRegex) {
                if (ngIdRegex.hasMatch(messages[i].id)) {
                  remove = true;
                  break;
                }
              }
            }
            if (!remove) {
              for (RegExp ngNameRegex in ngNamesRegex) {
                if (ngNameRegex.hasMatch(messages[i].name)) {
                  remove = true;
                  break;
                }
              }
            }
            if (!remove) {
              for (RegExp ngWordRegex in ngWordsRegex) {
                if (ngWordRegex.hasMatch(messages[i].text)) {
                  remove = true;
                  break;
                }
              }
            }

            if (remove) {
              messages.removeAt(i--);
            }
          }

          if (this.mounted) {
            setState(() {
              this.messages = messages;

              if (messages.isNotEmpty) {
                updateCount(messages[messages.length - 1].no);
                if (prevScrollIndex > 0) {
                  Preferences.setThreadScrollIndex(
                      prefs, widget.thread.dat, prevScrollIndex);
                  Preferences.setThreadScrollIndexLeading(
                      prefs, widget.thread.dat, prevScrollIndexLeading);
                }
              }

              this.loading = false;
            });
          }
        }).catchError((e, stackTrace) {
          if (this.mounted) {
            setState(() {
              this.loading = false;
            });
          }

          ScaffoldMessenger.of(_scaffoldKey.currentContext)
              .showSnackBar(SnackBar(
            duration: Duration(milliseconds: 3000),
            content: Text(e.toString() + ': ' + stackTrace.toString()),
          ));

          stderr.writeln(stackTrace.toString());
        });
      }).catchError((e, stackTrace) {
        if (this.mounted) {
          setState(() {
            this.loading = false;
          });
        }

        ScaffoldMessenger.of(_scaffoldKey.currentContext).showSnackBar(SnackBar(
          duration: Duration(milliseconds: 3000),
          content: Text(e.toString() + ': ' + stackTrace.toString()),
        ));

        stderr.writeln(stackTrace.toString());
      });
    });
  }

  void markAsReadAll(Thread thread) {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        Preferences.setThreadReadCount(prefs, thread.dat, thread.count);
      });
    });
  }

  void updateCount(int count) {
    SharedPreferences.getInstance().then((prefs) {
      List<Thread> threads = Preferences.getThreads(prefs);

      for (Thread thread in threads) {
        if (thread.dat == widget.thread.dat) {
          thread.count = count;
          Preferences.setThreads(prefs, threads);
          Preferences.setThreadReadCount(prefs, thread.dat, count);

          break;
        }
      }
    });
  }

  final _fontColorRegex = RegExp(r'<font color="#(.+)">(.+)</font>',
      multiLine: false, caseSensitive: false);

  Widget makeMessage(
      BuildContext context, int index, List<Message> originalMessages) {
    Message message = messages[index];
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
      if (message.name.contains('[') &&
          message.name.contains(']') &&
          message.name.contains('.')) {
        nameLinkifiers.add(IPLinkifier());
      }
    }

    const double scale = 0.85;
    int fontColor;
    String fontName;

    if (message.name.contains('<font color="#')) {
      Match fontColorMatch = _fontColorRegex.firstMatch(message.name);

      if (fontColorMatch.groupCount >= 1) {
        fontColor = int.tryParse('FF' + fontColorMatch.group(1), radix: 16);
      }
      if (fontColorMatch.groupCount >= 2) {
        fontName = fontColorMatch.group(2);
      }
    }

    final Widget nameWidget = (message.name.contains('(') &&
            message.name.contains(')'))
        ? SelectableLinkify(
            onOpen: (link) {
              List<Message> messagesByLinkable = [];

              for (message in originalMessages) {
                if (message.name
                    .toUpperCase()
                    .contains(link.url.toUpperCase())) {
                  messagesByLinkable.add(message);
                }
              }

              Navigator.push(context, MaterialPageRoute(
                builder: (BuildContext context) {
                  return ConstantMessageListWidget(
                      widget.thread, messagesByLinkable, originalMessages);
                },
              ));
            },
            text: message.name,
            options: LinkifyOptions(humanize: true),
            style: DefaultTextStyle.of(context)
                .style
                .apply(color: Colors.green, fontSizeFactor: scale),
            linkStyle: DefaultTextStyle.of(context).style.apply(
                color: Colors.green,
                fontSizeFactor: scale,
                decoration: TextDecoration.underline),
            linkifiers: nameLinkifiers,
            maxLines: null,
          )
        : Html(
            data: fontName ?? message.name,
            defaultTextStyle: DefaultTextStyle.of(context).style.apply(
                  color: fontColor == null ? Colors.green : Color(fontColor),
                  fontSizeFactor: scale,
                ),
            shrinkToFit: true,
          );

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SelectableLinkify(
              // No
              onOpen: (link) {
                Message message = findMessage(
                    originalMessages, int.parse(link.url.trim(), radix: 10));

                Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) {
                    return ConstantMessageListWidget(
                        widget.thread, message.responses, originalMessages);
                  },
                ));
              },
              text: '${message.no}',
              textAlign: TextAlign.left,
              linkifiers: [NoLinkifier(message)],
              options: LinkifyOptions(humanize: true),
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(color: noColor, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(
                  color: noColor,
                  fontSizeFactor: scale,
                  decoration: TextDecoration.underline),
              maxLines: 1,
            ),
            Flexible(child: nameWidget), // Name
            SelectableLinkify(
              // Address
              onOpen: (link) {},
              text: message.address,
              options: LinkifyOptions(humanize: true),
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(color: Colors.grey, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(
                  color: Colors.grey,
                  fontSizeFactor: scale,
                  decoration: TextDecoration.underline),
              linkifiers: [],
              maxLines: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SelectableLinkify(
              // Date
              onOpen: (link) {},
              text: message.date,
              options: LinkifyOptions(humanize: true),
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(color: Colors.grey, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(
                  color: Colors.grey,
                  fontSizeFactor: scale,
                  decoration: TextDecoration.underline),
              linkifiers: [],
              maxLines: 1,
            ),
            SelectableLinkify(
              // ID prefix
              onOpen: (link) {},
              text: 'ID(${message.postNo}/${message.postCount})',
              linkifiers: [],
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(color: idColor, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(
                  color: idColor,
                  fontSizeFactor: scale,
                  decoration: TextDecoration.underline),
              maxLines: 1,
            ),
            SelectableLinkify(
              // ID prefix
              onOpen: (link) {},
              text: ':',
              linkifiers: [],
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(color: Colors.grey, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(
                  color: Colors.grey,
                  fontSizeFactor: scale,
                  decoration: TextDecoration.underline),
              maxLines: 1,
            ),
            SelectableLinkify(
              // ID
              onOpen: (link) {
                List<Message> messagesById = [];

                for (message in originalMessages) {
                  if (message.id == link.url) {
                    messagesById.add(message);
                  }
                }

                Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) {
                    return ConstantMessageListWidget(
                        widget.thread, messagesById, originalMessages);
                  },
                ));
              },
              text: message.id,
              linkifiers: [IdLinkifier()],
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(color: idColor, fontSizeFactor: scale),
              linkStyle: DefaultTextStyle.of(context).style.apply(
                  color: idColor,
                  fontSizeFactor: scale,
                  decoration: TextDecoration.underline),
              maxLines: 1,
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Flexible(
              child: SelectableLinkify(
                // Message
                onOpen: (link) {
                  int linkAsInt = int.tryParse(link.url, radix: 10);

                  if (linkAsInt != null) {
                    Message message = findMessage(originalMessages, linkAsInt);

                    if (message != null) {
                      Navigator.of(context).push(PopupMessage(
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark,
                          originalMessages,
                          [message]));
                    }
                  } else if (link.url.startsWith('>>')) {
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
                        Message message = findMessage(originalMessages, i);

                        if (message != null) {
                          messages.add(message);
                        }
                      }

                      Navigator.of(context).push(PopupMessage(
                          MediaQuery.of(context).platformBrightness ==
                              Brightness.dark,
                          originalMessages,
                          messages));
                    } else {
                      Message message = findMessage(originalMessages,
                          int.parse(link.url.substring(2), radix: 10));

                      if (message != null) {
                        Navigator.of(context).push(PopupMessage(
                            MediaQuery.of(context).platformBrightness ==
                                Brightness.dark,
                            originalMessages,
                            [message]));
                      }
                    }
                  } else if (link.url.contains('://')) {
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

  Future<MapEntry<bool, PostMessage>> askNewMessage(BuildContext context) {
    return Navigator.of(context).push(AskNewMessage(
        MediaQuery.of(context).platformBrightness == Brightness.dark,
        initialPostMessage));
  }

  List<Message> getAllMessages() {
    return this.messages;
  }

  bool isFavorite() {
    for (Thread thread in Preferences.threads) {
      if (thread.dat == widget.thread.dat) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    try {
      var initialScrollIndex = Preferences.threadScrollIndex[widget.thread.dat];
      if (initialScrollIndex == null || initialScrollIndex < 0) {
        initialScrollIndex = 0;
      }
      initialScrollIndex = min(initialScrollIndex, messages.length - 1);

      var initialScrollIndexLeading =
          Preferences.threadScrollIndexLeading[widget.thread.dat];
      if (initialScrollIndexLeading == null || initialScrollIndexLeading < 0) {
        initialScrollIndexLeading = 0;
      }

      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(title: Text(widget.thread.title), actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.swap_vert),
            tooltip: 'ジャンプ',
            onPressed: () {
              askNewItem(context, 'ジャンプ先レス番号を入力してください', 'レス番号',
                      TextInputType.number)
                  .then((no) {
                if (no != null && mounted) {
                  int resNo = int.tryParse(no);
                  if (resNo == null) {
                    return;
                  }

                  resNo = max(0, min(resNo - 1, messages.length - 1));
                  itemScrollController.scrollTo(
                      index: resNo, duration: Duration(milliseconds: 300));
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'スレッドタイトルとURLをコピー',
            onPressed: () async {
              final title = await getThreadTitle(widget.thread);
              final url = getThreadUrl(widget.thread, '/l50');
              String text = title;
              if (text == null || text.isEmpty) {
                text = url;
              } else {
                text += '\n' + url;
              }
              final cd = ClipboardData(text: text);

              Clipboard.setData(cd);

              ScaffoldMessenger.of(_scaffoldKey.currentContext)
                  .showSnackBar(SnackBar(
                duration: Duration(milliseconds: 1000),
                content: Text('スレッドタイトルとURLをコピーしました'),
              ));
            },
          ),
          IconButton(
            icon: isFavorite()
                ? const Icon(Icons.favorite)
                : const Icon(Icons.favorite_border),
            tooltip: 'お気に入りに追加/削除',
            onPressed: () {
              SharedPreferences.getInstance().then((prefs) {
                List<Thread> threads = Preferences.getThreads(prefs);
                bool contains = false;

                for (Thread thread in threads) {
                  if (thread.dat == widget.thread.dat) {
                    contains = true;
                    threads.remove(thread);

                    break;
                  }
                }

                if (contains) {
                  setState(() {
                    Preferences.setThreads(prefs, threads);

                    ScaffoldMessenger.of(_scaffoldKey.currentContext)
                        .showSnackBar(SnackBar(
                      duration: Duration(milliseconds: 1000),
                      content: Text('お気に入りから削除しました'),
                    ));
                  });
                } else {
                  setState(() {
                    threads.add(widget.thread);
                    Preferences.setThreads(prefs, threads);

                    ScaffoldMessenger.of(_scaffoldKey.currentContext)
                        .showSnackBar(SnackBar(
                      duration: Duration(milliseconds: 1000),
                      content: Text('お気に入りに登録しました'),
                    ));
                  });
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'ブラウザで開く',
            onPressed: () {
              openThread(widget.thread);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'リロード',
            onPressed: () {
              getMessages();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '検索',
            onPressed: () {
              askNewItem(context, '検索ワードを入力してください', '検索ワード', null).then((word) {
                if (word != null && mounted) {
                  List<Message> searched = [];
                  var upperWord = word.toUpperCase();

                  for (var message in this.messages) {
                    if (message.name.toUpperCase().contains(upperWord)) {
                      searched.add(message);
                    } else if (message.id.toUpperCase().contains(upperWord)) {
                      searched.add(message);
                    } else if (message.text.toUpperCase().contains(upperWord)) {
                      searched.add(message);
                    }
                  }

                  Navigator.push(context, MaterialPageRoute(
                    builder: (BuildContext context) {
                      return ConstantMessageListWidget(
                          widget.thread, searched, getAllMessages());
                    },
                  ));
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: '投稿',
            onPressed: () {
              askNewMessage(context).then((message) {
                if (message != null &&
                    message.key == true &&
                    message.value != null &&
                    message.value.message != null &&
                    mounted) {
                  auth(widget.thread).then((sid) {
                    bbs(widget.thread, message.value.from, message.value.mail,
                            message.value.message, sid)
                        .then((resp) {
                      Future<String> bodyFuture;

                      if (widget.thread.board.url.contains('shitaraba')) {
                        bodyFuture = decodeEucJP(resp.bodyBytes);
                      } else {
                        bodyFuture = decodeJIS(resp.bodyBytes);
                      }

                      if (bodyFuture == null) {
                        ScaffoldMessenger.of(_scaffoldKey.currentContext)
                            .showSnackBar(SnackBar(
                          duration: Duration(milliseconds: 1000),
                          content: Text("body future is null"),
                        ));

                        return;
                      }

                      bodyFuture.then((body) {
                        if (!body.contains('<title>ＥＲＲＯＲ！</title>') &&
                            !body.contains('<title>ERROR!!</title>') &&
                            body.contains('<title>書きこみました') &&
                            resp.statusCode == 200) {
                          initialPostMessage = PostMessage();

                          ScaffoldMessenger.of(_scaffoldKey.currentContext)
                              .showSnackBar(SnackBar(
                                  duration: Duration(milliseconds: 1000),
                                  content: Html(data: body, shrinkToFit: true)));

                          if (messages.isNotEmpty) {
                            updateCount(messages[messages.length - 1].no + 1);
                          }
                        } else {
                          initialPostMessage = message.value;

                          if (body.contains('浪人SID')) {
                            // ERROR: 浪人SIDが正しくありません。再度ログインしてみてください。
                            ScaffoldMessenger.of(_scaffoldKey.currentContext)
                                .showSnackBar(SnackBar(
                              duration: Duration(milliseconds: 3000),
                              content: Text('浪人SIDが正しくありません。再度ログインしてみてください。ID=' + Preferences.fiveChAPIID + ', PW=' + Preferences.fiveChAPIPW),
                            ));
                          } else {
                            ScaffoldMessenger.of(_scaffoldKey.currentContext)
                                .showSnackBar(SnackBar(
                              duration: Duration(milliseconds: 3000),
                              content: Html(data: body, shrinkToFit: true),
                            ));
                          }

                          stderr.writeln(body);
                        }
                      }).catchError((e, stackTrace) {
                        initialPostMessage = message.value;

                        ScaffoldMessenger.of(_scaffoldKey.currentContext)
                            .showSnackBar(SnackBar(
                          duration: Duration(milliseconds: 3000),
                          content:
                              Text(e.toString() + ': ' + stackTrace.toString()),
                        ));

                        stderr.writeln(stackTrace.toString());
                      });
                    }).catchError((e, stackTrace) {
                      initialPostMessage = message.value;

                      ScaffoldMessenger.of(_scaffoldKey.currentContext)
                          .showSnackBar(SnackBar(
                        duration: Duration(milliseconds: 3000),
                        content:
                            Text(e.toString() + ': ' + stackTrace.toString()),
                      ));

                      stderr.writeln(stackTrace.toString());
                    });
                  }).catchError((e, stackTrace) {
                    initialPostMessage = message.value;

                    ScaffoldMessenger.of(_scaffoldKey.currentContext)
                        .showSnackBar(SnackBar(
                      duration: Duration(milliseconds: 3000),
                      content:
                          Text(e.toString() + ': ' + stackTrace.toString()),
                    ));

                    stderr.writeln(stackTrace.toString());
                  });
                } else if (message != null && message.key == false) {
                  initialPostMessage = message.value;
                }
              }).catchError((e, stackTrace) {
                ScaffoldMessenger.of(_scaffoldKey.currentContext)
                    .showSnackBar(SnackBar(
                  duration: Duration(milliseconds: 3000),
                  content: Text(e.toString() + ': ' + stackTrace.toString()),
                ));

                stderr.writeln(stackTrace.toString());
              });
            },
          ),
        ]),
        body: loading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  if (disableRefresh) {
                    return;
                  }
                  getMessages();
                },
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (details.primaryDelta > 15) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Scrollbar(
                    child: ScrollablePositionedList.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemScrollController: itemScrollController,
                      itemPositionsListener: itemPositionsListener,
                      initialScrollIndex: initialScrollIndex,
                      initialAlignment: initialScrollIndexLeading,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            makeMessage(context, index, getAllMessages()),
                            Divider(height: 2),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
      );
    } catch (e, stackTrace) {
      stderr.writeln(stackTrace);

      return Text(stackTrace.toString());
    }
  }
}

class ConstantMessageListWidget extends MessageListWidget {
  final Thread thread;
  final List<Message> messages;
  final List<Message> originalMessages;

  const ConstantMessageListWidget(
      this.thread, this.messages, this.originalMessages,
      {Key key})
      : super(thread, key: key);

  @override
  State<StatefulWidget> createState() {
    return ConstantMessageListState();
  }
}

class ConstantMessageListState extends MessageListState {
  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    messages = (widget as ConstantMessageListWidget).messages;
  }

  @override
  void saveThreadScrollIndex() {}

  @override
  void getMessages() {
    setState(() {
      this.messages = (widget as ConstantMessageListWidget).messages;
    });
  }

  List<Message> getAllMessages() {
    return (widget as ConstantMessageListWidget).originalMessages;
  }
}

final _anchorRegex = RegExp(r'>>(\d+)', multiLine: false, caseSensitive: false);
final _anchorMultiRegex =
    RegExp(r'>>(\d+)-(\d+)', multiLine: false, caseSensitive: false);
final _anchorRegex2 =
    RegExp(r'(?<![\d>])(\d\d\d)(?!\d)', multiLine: false, caseSensitive: false);

class AnchorLinkifier extends Linkifier {
  const AnchorLinkifier();

  @override
  List<LinkifyElement> parse(elements, options) {
    final list = <LinkifyElement>[];

    elements.forEach((element) {
      if (element is TextElement) {
        var match = !element.text.contains('>>')
            ? null
            : _anchorMultiRegex.firstMatch(element.text);

        if (match == null) {
          match = !element.text.contains('>>')
              ? null
              : _anchorRegex.firstMatch(element.text);

          if (match == null) {
            match = _anchorRegex2.firstMatch(element.text);

            if (match == null) {
              list.add(element);
            } else {
              list.addAll(parse(
                  [TextElement(element.text.substring(0, match.start))],
                  options));
              list.add(LinkableElement(match.group(0), match.group(0)));
              list.addAll(parse(
                  [TextElement(element.text.substring(match.end))], options));
            }
          } else {
            list.addAll(parse(
                [TextElement(element.text.substring(0, match.start))],
                options));
            list.add(LinkableElement(match.group(0), match.group(0)));
            list.addAll(parse(
                [TextElement(element.text.substring(match.end))], options));
          }
        } else {
          list.addAll(parse(
              [TextElement(element.text.substring(0, match.start))], options));
          list.add(LinkableElement(match.group(0), match.group(0)));
          list.addAll(
              parse([TextElement(element.text.substring(match.end))], options));
        }
      } else {
        list.add(element);
      }
    });

    return list;
  }
}

class IdLinkifier extends Linkifier {
  const IdLinkifier();

  @override
  List<LinkifyElement> parse(elements, options) {
    final list = <LinkifyElement>[];

    elements.forEach((element) {
      if (element is TextElement) {
        list.add(LinkableElement(element.text, element.text));
      } else {
        list.add(element);
      }
    });

    return list;
  }
}

final _wacchoiRegex =
    RegExp(r'....-....', multiLine: false, caseSensitive: false);

class WacchoiLinkifier extends Linkifier {
  const WacchoiLinkifier();

  @override
  List<LinkifyElement> parse(elements, options) {
    final list = <LinkifyElement>[];

    elements.forEach((element) {
      if (element is TextElement) {
        final match = !element.text.contains('(') ||
                !element.text.contains(')') ||
                !element.text.contains('-')
            ? null
            : _wacchoiRegex.firstMatch(element.text);

        if (match == null) {
          list.add(element);
        } else {
          list.addAll(parse(
              [TextElement(element.text.substring(0, match.start))], options));
          list.add(LinkableElement(match.group(0), match.group(0)));
          list.addAll(
              parse([TextElement(element.text.substring(match.end))], options));
        }
      } else {
        list.add(element);
      }
    });

    return list;
  }
}

final _ipRegex =
    RegExp(r'(?:\d{1,3}\.){3}\d{1,3}', multiLine: false, caseSensitive: false);

class IPLinkifier extends Linkifier {
  const IPLinkifier();

  @override
  List<LinkifyElement> parse(elements, options) {
    final list = <LinkifyElement>[];

    elements.forEach((element) {
      if (element is TextElement) {
        final match = !element.text.contains('[') ||
                !element.text.contains(']') ||
                !element.text.contains('.')
            ? null
            : _ipRegex.firstMatch(element.text);

        if (match == null) {
          list.add(element);
        } else {
          list.addAll(parse(
              [TextElement(element.text.substring(0, match.start))], options));
          list.add(LinkableElement(match.group(0), match.group(0)));
          list.addAll(
              parse([TextElement(element.text.substring(match.end))], options));
        }
      } else {
        list.add(element);
      }
    });

    return list;
  }
}

class NoLinkifier extends Linkifier {
  final Message message;

  const NoLinkifier(this.message);

  @override
  List<LinkifyElement> parse(elements, options) {
    final list = <LinkifyElement>[];

    elements.forEach((element) {
      if (element is TextElement) {
        if (this.message.responses.isEmpty) {
          list.add(element);
        } else {
          list.add(LinkableElement(element.text, element.text));
        }
      } else {
        list.add(element);
      }
    });

    return list;
  }
}
