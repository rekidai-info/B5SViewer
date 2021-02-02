import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '5ch_api.dart';
import 'board.dart';
import 'preferences.dart';

final GlobalKey<BoardSearchState> _boardSearchWidgetKey =
    GlobalKey<BoardSearchState>(debugLabel: 'BoardSearchWidget');
final RegExp _fiveChBoardUrlRegex =
    RegExp(r'<A HREF=(.+)>(.+)</A>', multiLine: true, caseSensitive: false);

class BoardSearchWidget extends StatefulWidget {
  BoardSearchWidget({Key key}) : super(key: _boardSearchWidgetKey);

  @override
  State<StatefulWidget> createState() {
    return BoardSearchState();
  }
}

class BoardSearchState extends State<BoardSearchWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'BoardSearchState');
  bool loading;
  List<Board> boards;
  List<Board> searchedBoards;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    loading = true;
    boards = [];
    searchedBoards = [];
    getBoards();
  }

  void getBoards() async {
    setState(() {
      loading = true;
    });

    var resp = await http.get('https://menu.5ch.net/bbsmenu.html', headers: {
      'User-Agent': Preferences.fiveChAPIUARead,
      'Connection': 'close',
      'Accept-Encoding': 'gzip',
    }).timeout(Duration(milliseconds: 8000));

    final matches =
        _fiveChBoardUrlRegex.allMatches(await decodeJIS(resp.bodyBytes));

    setState(() {
      boards.clear();
      searchedBoards.clear();
      for (RegExpMatch match in matches) {
        String url = match.group(1);
        String name = match.group(2);

        if (name.toUpperCase().contains("HTTP://")) {
          continue;
        }

        boards.add(Board(url, name));
        searchedBoards.add(Board(url, name));
      }
      loading = false;
    });
  }

  Widget makeBoard(BuildContext context, int index) {
    return ListTile(
        dense: true,
        title: Text(searchedBoards[index].name,
            style:
                DefaultTextStyle.of(context).style.apply(fontSizeFactor: 0.9)),
        onTap: () {
          Navigator.of(context).pop(searchedBoards[index]);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('板検索'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '検索',
            onPressed: () {
              askNewItem(context, '検索ワードを入力してください', '検索ワード', null).then((word) {
                if (word != null && mounted) {
                  setState(() {
                    searchedBoards = [];
                    for (Board board in boards) {
                      if (board.name != null &&
                          board.name
                              .toUpperCase()
                              .contains(word.toUpperCase())) {
                        searchedBoards.add(board);
                      }
                    }
                  });
                }
              });
            },
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Scrollbar(
              child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: searchedBoards.length,
                  itemBuilder: (context, index) {
                    return makeBoard(context, index);
                  }),
            ),
    );
  }
}
