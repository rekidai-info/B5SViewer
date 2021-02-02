import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '5ch_api.dart';
import 'board.dart';
import 'message_list.dart';
import 'preferences.dart';
import 'thread.dart';

class ThreadListWidget extends StatefulWidget {
  final Board board;

  const ThreadListWidget(this.board, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ThreadListState();
  }
}

class ThreadListState extends State<ThreadListWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'ThreadListState');
  bool loading;
  List<Thread> threads;
  List<Thread> filtered;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    loading = false;
    threads = [];
    filtered = [];
    getThreads();
  }

  void getThreads() {
    SharedPreferences.getInstance().then((prefs) {
      subject(widget.board).then((threads) {
        if (this.mounted) {
          setState(() {
            this.threads = threads;
            this.filtered = threads;
          });
        }
      }).catchError((e, stackTrace) {
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

  void filter(String word) {
    List<Thread> result = [];
    String upperWord = word.toUpperCase();

    for (var thread in this.threads) {
      if (thread.title.toUpperCase().contains(upperWord)) {
        result.add(thread);
      }
    }

    setState(() {
      this.filtered = result;
    });
  }

  Widget makeThread(BuildContext context, int index) {
    int readCount = Preferences.threadReadCount[filtered[index].dat];
    if (readCount == null) {
      readCount = 0;
    }
    int messageCount = filtered[index].count;
    for (int i = 0; i < Preferences.threads.length; ++i) {
      if (Preferences.threads[i].dat == filtered[index].dat) {
        messageCount = Preferences.threads[i].count;
        break;
      }
    }
    int newCount = max(0, messageCount - readCount);

    Icon leadingIcon;
    if (messageCount >= 1000) {
      leadingIcon = Icon(Icons.lens, color: Colors.red);
    } else if (Preferences.threadReadCount[filtered[index].dat] == null) {
      leadingIcon = Icon(Icons.lens, color: Colors.black);
    } else if (readCount == messageCount) {
      leadingIcon = Icon(Icons.lens, color: Colors.grey);
    } else {
      leadingIcon = Icon(Icons.lens, color: Colors.blue);
    }

    return Dismissible(
      direction: DismissDirection.endToStart,
      key: Key(filtered[index].dat + '_dismissible'),
      confirmDismiss: (direction) {
        return confirm(context).then((result) {
          if (result) {
            setState(() {
              SharedPreferences.getInstance().then((prefs) {
                Preferences.removeThreadReadCount(prefs, filtered[index].dat);
                Preferences.removeThreadScrollIndex(prefs, filtered[index].dat);
                Preferences.removeThreadScrollIndexLeading(
                    prefs, filtered[index].dat);
              });
            });
          }

          return false;
        });
      },
      background: new Container(
        padding: EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: new Align(
          alignment: Alignment.centerRight,
          child: new Text('削除',
              textAlign: TextAlign.right,
              style: new TextStyle(color: Colors.white)),
        ),
      ),
      child: ListTile(
          dense: true,
          leading: leadingIcon,
          title: Text(filtered[index].title,
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(fontSizeFactor: 0.9)),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 64,
                child: Text('$newCount New!\n$readCount/$messageCount',
                    style: DefaultTextStyle.of(context)
                        .style
                        .apply(fontSizeFactor: 0.9)),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (BuildContext context) {
                return MessageListWidget(filtered[index]);
              },
            ));
            markAsReadAll(filtered[index]);
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('スレッド一覧'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'リロード',
            onPressed: () {
              getThreads();
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '検索',
            onPressed: () {
              askNewItem(context, '検索ワードを入力してください', '検索ワード', null).then((word) {
                if (word != null && mounted) {
                  filter(word);
                }
              });
            },
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {},
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (details.primaryDelta > 15) {
                    Navigator.of(context).pop();
                  }
                },
                child: Scrollbar(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          makeThread(context, index),
                          Divider(height: 1),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }
}
