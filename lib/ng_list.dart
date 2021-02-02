import 'package:flutter/material.dart';

import 'preferences.dart';

final GlobalKey<NGListState> _ngListWidgetKey =
    GlobalKey<NGListState>(debugLabel: 'NGListWidget');

abstract class NGListWidget extends StatefulWidget {
  NGListWidget({Key key}) : super(key: _ngListWidgetKey);

  State<StatefulWidget> createState();
}

abstract class NGListState extends State<NGListWidget> {
  List<String> ngs;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();

    ngs = [];
    getNGs();
  }

  GlobalKey<ScaffoldState> getScaffoldKey();
  void getNGs();
  void addNG(String ng);
  void removeNG(int index);

  String getTitle();

  Widget makeNG(BuildContext context, int index) {
    return Dismissible(
      direction: DismissDirection.endToStart,
      key: Key(this.ngs[index] + '_dismissible'),
      confirmDismiss: (direction) {
        return confirm(context);
      },
      onDismissed: (direction) {
        removeNG(index);
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
        title: Text(this.ngs[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: getScaffoldKey(),
      appBar: AppBar(
        title: Text(getTitle()),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '追加',
            onPressed: () {
              askNewItem(context, 'NGキーワードを入力してください', 'NGキーワード', null)
                  .then((ng) {
                if (ng != null && mounted) {
                  addNG(ng);
                }
              });
            },
          ),
        ],
      ),
      body: Scrollbar(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: ngs.length,
          itemBuilder: (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                makeNG(context, index),
                Divider(),
              ],
            );
          },
        ),
      ),
    );
  }
}
