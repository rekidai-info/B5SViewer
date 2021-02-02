import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ng_list.dart';
import 'preferences.dart';

final GlobalKey<NGWordListState> _ngWordListWidgetKey = GlobalKey<NGWordListState>(debugLabel: 'NGWordListWidget');

class NGWordListWidget extends NGListWidget {
  NGWordListWidget({Key key }) : super(key: _ngWordListWidgetKey);

  @override
  State<StatefulWidget> createState() {
    return NGWordListState();
  }
}

class NGWordListState extends NGListState {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'NGWordListState');

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();
  }

  @override
  GlobalKey<ScaffoldState> getScaffoldKey() {
    return _scaffoldKey;
  }

  @override
  void getNGs() {
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        ngs = Preferences.getNGWords(prefs);
      });
    });
  }

  @override
  void addNG(String ng) {
    if (!ngs.contains(ng)) {
      SharedPreferences.getInstance().then((prefs) {
        setState(() {
          ngs.add(ng);
          Preferences.setNGWords(prefs, ngs);
        });
      });
    }
  }

  @override
  void removeNG(int index) {
    setState(() {
      String removed = this.ngs.removeAt(index);

      SharedPreferences.getInstance().then((prefs) {
        Preferences.setNGWords(prefs, this.ngs);
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$removedを削除しました")));
    });
  }

  String getTitle() {
    return 'NG Word';
  }
}
