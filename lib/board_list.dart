import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'board.dart';
import 'board_search.dart';
import 'preferences.dart';
import 'thread_list.dart';

final GlobalKey<BoardListState> _boardListWidgetKey =
    GlobalKey<BoardListState>(debugLabel: 'BoardListWidget');

class BoardListWidget extends StatefulWidget {
  BoardListWidget({Key key}) : super(key: _boardListWidgetKey);

  @override
  State<StatefulWidget> createState() {
    return BoardListState();
  }
}

class BoardListState extends State<BoardListWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(debugLabel: 'BoardListState');
  bool loading;
  List<Board> boards;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    loading = false;
    boards = [];
    getBoards();
  }

  void getBoards() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        boards = Preferences.getBoards(prefs);
      });
    });
  }

  Widget makeBoard(BuildContext context, int index) {
    return Dismissible(
      direction: DismissDirection.endToStart,
      key: Key(this.boards[index].url +
          '_' +
          this.boards[index].name +
          '_dismissible'),
      confirmDismiss: (direction) {
        return confirm(context);
      },
      onDismissed: (direction) {
        Board board = this.boards[index];

        setState(() {
          this.boards.removeAt(index);

          SharedPreferences.getInstance().then((prefs) {
            setState(() {
              Preferences.setBoards(prefs, this.boards);
            });
          });
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("${board.name}を削除しました")));
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
      child: GestureDetector(
        onDoubleTap: () {
          askNewBoard(context, '編集する板の URL と名前（任意）を入力してください',
                  this.boards[index].url, this.boards[index].name)
              .then((board) {
            if (board != null && mounted) {
              setState(() {
                this.boards[index] = Board(board.key, board.value);

                SharedPreferences.getInstance().then((prefs) {
                  Preferences.setBoards(prefs, this.boards);
                });
              });
            }
          });
        },
        child: ListTile(
          dense: true,
          title: Text(boards[index].name,
              style: DefaultTextStyle.of(context)
                  .style
                  .apply(fontSizeFactor: 0.9)),
          // trailing: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (BuildContext context) {
                return ThreadListWidget(boards[index]);
              },
            ));
          },
        ),
      ),
    );
  }

  Future<MapEntry<String, String>> askNewBoard(BuildContext context,
      String title, String initialUrl, String initialName) async {
    String url, name;

    return await showDialog<MapEntry<String, String>>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: TextEditingController(text: initialUrl),
                decoration: InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://medaka.5ch.net/otoge/'),
                onChanged: (value) {
                  url = value;
                  if (!url.startsWith('https://') &&
                      !url.startsWith('http://')) {
                    url = 'https://' + url;
                  }
                  if (!url.endsWith('/')) {
                    url += '/';
                  }
                },
              ),
              TextField(
                controller: TextEditingController(text: initialName),
                decoration: InputDecoration(labelText: '名前', hintText: '音ゲー'),
                onChanged: (value) {
                  name = value;
                },
              ),
            ]),
            actions: <Widget>[
              TextButton(
                child: Text('板検索'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute<Board>(
                    builder: (BuildContext context) {
                      return BoardSearchWidget();
                    },
                  )).then((board) {
                    if (board != null &&
                        board.url != null &&
                        board.name != null) {
                      Navigator.of(context)
                          .pop(MapEntry<String, String>(board.url, board.name));
                    }
                  }).catchError((e, stackTrace) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      duration: Duration(milliseconds: 3000),
                      content: Text(e.toString() + ': ' + stackTrace.toString()),
                    ));
                  });
                },
              ),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  if (url != null &&
                      url.isNotEmpty &&
                      name != null &&
                      name.isNotEmpty) {
                    Navigator.of(context)
                        .pop(MapEntry<String, String>(url, name));
                  }
                },
              )
            ],
          );
        });
  }

  void addNewBoard() {
    askNewBoard(context, '新規に登録する板の URL と名前（任意）を入力してください', '', '')
        .then((board) {
      if (board != null && mounted) {
        Board newBoard = Board(board.key, board.value);

        setState(() {
          this.boards.add(newBoard);

          SharedPreferences.getInstance().then((prefs) {
            Preferences.setBoards(prefs, this.boards);
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    this.boards = Preferences.boards;

    List<Widget> childrenBoards = [];

    for (int i = 0; i < boards.length; ++i) {
      childrenBoards.add(Card(
        key: Key(this.boards[i].url + '_' + this.boards[i].name + '_card'),
        child: makeBoard(context, i),
        margin: EdgeInsets.all(1.0),
      ));
    }

    return Scaffold(
      key: _scaffoldKey,
      body: loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                getBoards();
              },
              child: Scrollbar(
                child: ReorderableListView(
                  children: childrenBoards,
                  onReorder: (int oldIndex, int newIndex) {
                    if (oldIndex == newIndex) {
                      return;
                    }

                    List<Board> newOrder = [];
                    Board oldBored = boards.removeAt(oldIndex);

                    if (oldIndex < newIndex) {
                      for (int i = 0; i <= boards.length; ++i) {
                        if (i == newIndex - 1) {
                          newOrder.add(oldBored);
                        }
                        if (i < boards.length) {
                          newOrder.add(boards[i]);
                        }
                      }
                    } else {
                      for (int i = 0; i < boards.length; ++i) {
                        if (i == newIndex) {
                          newOrder.add(oldBored);
                        }
                        if (i < boards.length) {
                          newOrder.add(boards[i]);
                        }
                      }
                    }

                    SharedPreferences.getInstance().then((prefs) {
                      Preferences.setBoards(prefs, newOrder);
                      setState(() {});
                    });
                  },
                ),
              ),
            ),
    );
  }
}
