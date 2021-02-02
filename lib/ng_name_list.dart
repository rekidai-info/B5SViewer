import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ng_list.dart';
import 'preferences.dart';

final GlobalKey<NGNameListState> _ngNameListWidgetKey = GlobalKey<NGNameListState>(debugLabel: 'NGNameListWidget');

class NGNameListWidget extends NGListWidget {
  NGNameListWidget({Key key }) : super(key: _ngNameListWidgetKey);

  @override
  State<StatefulWidget> createState() {
    return NGNameListState();
  }
}

class NGNameListState extends NGListState {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'NGNameListState');

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
        ngs = Preferences.getNGNames(prefs);
      });
    });
  }

  @override
  void addNG(String ng) {
    if (!ngs.contains(ng)) {
      SharedPreferences.getInstance().then((prefs) {
        setState(() {
          ngs.add(ng);
          Preferences.setNGNames(prefs, ngs);
        });
      });
    }
  }

  @override
  void removeNG(int index) {
    setState(() {
      String removed = this.ngs.removeAt(index);

      SharedPreferences.getInstance().then((prefs) {
        Preferences.setNGNames(prefs, this.ngs);
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$removedを削除しました")));
    });
  }

  String getTitle() {
    return 'NG Name';
  }
}
