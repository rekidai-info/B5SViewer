import 'dart:async';
import 'dart:io';
import 'dart:math';

import '5ch_api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'message_list.dart';
import 'preferences.dart';
import 'thread.dart';

final GlobalKey<FavoriteThreadListState> _favoriteThreadListWidgetKey = GlobalKey<FavoriteThreadListState>(debugLabel: 'FavoriteThreadListWidget');

class FavoriteThreadListWidget extends StatefulWidget {
  FavoriteThreadListWidget({Key key }) : super(key: _favoriteThreadListWidgetKey);

  @override
  State<StatefulWidget> createState() {
    return FavoriteThreadListState();
  }
}

class FavoriteThreadListState extends State<FavoriteThreadListWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'FavoriteThreadListState');
  bool loading;
  List<Thread> threads;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    this.loading = false;
    this.threads = Preferences.threads;

    getFavoriteThread();
  }

  Future<void> updateCount() async {
    if (this.threads.length <= 0) {
      setState(() {
        this.loading = false;
      });

      return;
    }

    Map<String, List<Thread>> latestThreads = {};

    for (Thread thread in this.threads) {
      if (latestThreads[thread.board.url] == null) {
        try {
          latestThreads[thread.board.url] = await subject(thread.board);
        } on TimeoutException catch (_) {
          latestThreads[thread.board.url] = [];

          ScaffoldMessenger.of(_scaffoldKey.currentContext).showSnackBar(SnackBar(
            duration: Duration(milliseconds: 1000),
            content: Text('タイムアウト：' + thread.board.name),
          ));
        } catch (e, stackTrace) {
          latestThreads[thread.board.url] = [];

          ScaffoldMessenger.of(_scaffoldKey.currentContext).showSnackBar(SnackBar(
            duration: Duration(milliseconds: 3000),
            content: Text('エラー ' + thread.board.name + ': ' + e.toString()),
          ));

          stderr.writeln(stackTrace.toString());
        }
      }

      if (latestThreads[thread.board.url] != null) {
        for (Thread latestThread in latestThreads[thread.board.url]) {
          if (thread.dat == latestThread.dat) {
            thread.count = latestThread.count;
            break;
          }
        }
      }
    }

    SharedPreferences.getInstance().then((prefs) {
      Preferences.setThreads(prefs, this.threads);
    });

    setState(() {
      this.loading = false;
    });
  }

  Future<void> getFavoriteThread() async {
    if (this.mounted) {
      setState(() {
        this.loading = true;
      });
    }

    var prefs = await SharedPreferences.getInstance();

    setState(() {
      this.threads = Preferences.getThreads(prefs);
    });

    if (this.mounted) {
      setState(() {
        updateCount().catchError((e, stackTrace) {
          this.loading = false;

          ScaffoldMessenger.of(_scaffoldKey.currentContext).showSnackBar(SnackBar(
            duration: Duration(milliseconds: 3000),
            content: Text(e.toString() + ': ' + stackTrace.toString()),
          ));
        });
      });
    }
  }

  Widget makeThread(BuildContext context, int index) {
    int readCount = Preferences.threadReadCount[threads[index].dat];
    if (readCount == null) {
      readCount = 0;
    }
    int messageCount = Preferences.threads[index].count;
    if (messageCount == null) {
      messageCount = threads[index].count;
    }
    int newCount = max(0, messageCount - readCount);

    Icon leadingIcon;
    if (messageCount >= 1000) {
      leadingIcon = Icon(Icons.lens, color: Colors.red);
    } else if (Preferences.threadReadCount[threads[index].dat] == null) {
      leadingIcon = Icon(Icons.lens, color: Colors.black);
    } else if (readCount == messageCount) {
      leadingIcon = Icon(Icons.lens, color: Colors.grey);
    } else {
      leadingIcon = Icon(Icons.lens, color: Colors.blue);
    }

    return Dismissible(
      direction: DismissDirection.endToStart,
      key: Key(this.threads[index].dat + '_dismissible'),
      confirmDismiss: (direction) {
        return confirm(context);
      },
      onDismissed: (direction) {
        Thread thread = this.threads[index];

        setState(() {
          this.threads.removeAt(index);

          SharedPreferences.getInstance().then(
            (prefs) {
              setState(() {
                Preferences.setThreads(prefs, this.threads);
              });
            }
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${thread.title}を削除しました")));
      },
      background: new Container(
        padding: EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: new Align(
          alignment: Alignment.centerRight,
          child: new Text(
            '削除',
            textAlign: TextAlign.right,
            style: new TextStyle(color: Colors.white)
          ),
        ),
      ),
      child: ListTile(
        dense: true,
        leading: leadingIcon,
        title: Text(threads[index].title, style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 0.9)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 64,
              child: Text('$newCount New!\n$readCount/$messageCount', style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 0.9)),
            ),
          ],
        ),
        onTap: () {            
          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return MessageListWidget(threads[index]);
            },
          )).then((var v) {
            setState(() {});
          });
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> childrenThreads = [];

    for (int i = 0; i < this.threads.length; ++i) {
      childrenThreads.add(Card(
        key: Key(this.threads[i].dat + '_' + this.threads[i].title + '_card'),
        child: makeThread(context, i),
        margin: EdgeInsets.all(1.0),
      ));
    }

    return Scaffold(
      key: _scaffoldKey,
      body: loading ? Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: () async {
          getFavoriteThread();
        },
        child: Scrollbar(
          child: ReorderableListView(
            children: childrenThreads,
            onReorder: (int oldIndex, int newIndex) {
              if (oldIndex == newIndex) {
                return;
              }

              List<Thread> newOrder = [];
              Thread oldThread = this.threads.removeAt(oldIndex);

              if (oldIndex < newIndex) {
                for (int i = 0; i <= threads.length; ++i) {
                  if (i == newIndex - 1) {
                    newOrder.add(oldThread);
                  }
                  if (i < threads.length) {
                    newOrder.add(threads[i]);
                  }
                }
              } else {
                for (int i = 0; i < threads.length; ++i) {
                  if (i == newIndex) {
                    newOrder.add(oldThread);
                  }
                  if (i < threads.length) {
                    newOrder.add(threads[i]);
                  }
                }
              }

              setState(() {
                this.threads = newOrder;
              });

              SharedPreferences.getInstance().then((prefs) {
                Preferences.setThreads(prefs, newOrder);
              });
            },
          ),
        ),
      ),
    );
  }
}
