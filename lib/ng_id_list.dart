import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ng_list.dart';
import 'preferences.dart';

final GlobalKey<NGIdListState> _ngIdListWidgetKey =
    GlobalKey<NGIdListState>(debugLabel: 'NGIdListWidget');

class NGIdListWidget extends NGListWidget {
  NGIdListWidget({Key key}) : super(key: _ngIdListWidgetKey);

  @override
  State<StatefulWidget> createState() {
    return NGIdListState();
  }
}

class NGIdListState extends NGListState {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(debugLabel: 'NGIdListState');

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
        ngs = Preferences.getNGIds(prefs);
      });
    });
  }

  @override
  void addNG(String ng) {
    if (!ngs.contains(ng)) {
      SharedPreferences.getInstance().then((prefs) {
        setState(() {
          ngs.add(ng);
          Preferences.setNGIds(prefs, ngs);
        });
      });
    }
  }

  @override
  void removeNG(int index) {
    setState(() {
      String removed = this.ngs.removeAt(index);

      SharedPreferences.getInstance().then((prefs) {
        Preferences.setNGIds(prefs, this.ngs);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("$removedを削除しました")));
    });
  }

  String getTitle() {
    return 'NG ID';
  }
}
