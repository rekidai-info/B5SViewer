import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ng_list.dart';
import 'preferences.dart';

final GlobalKey<NGNameRegexListState> _ngNameRegexListWidgetKey = GlobalKey<NGNameRegexListState>(debugLabel: 'NGNameRegexListWidget');

class NGNameRegexListWidget extends NGListWidget {
  NGNameRegexListWidget({Key key }) : super(key: _ngNameRegexListWidgetKey);

  @override
  State<StatefulWidget> createState() {
    return NGNameRegexListState();
  }
}

class NGNameRegexListState extends NGListState {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'NGNameRegexListState');

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
        ngs = Preferences.getNGNamesRegex(prefs);
      });
    });
  }

  @override
  void addNG(String ng) {
    if (!ngs.contains(ng)) {
      SharedPreferences.getInstance().then((prefs) {
        try {
          RegExp(ng, multiLine: false, caseSensitive: false);
          setState(() {
            ngs.add(ng);
            Preferences.setNGNamesRegex(prefs, ngs);
          });
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("${e.toString()}")));
        }
      });
    }
  }

  @override
  void removeNG(int index) {
    setState(() {
      String removed = this.ngs.removeAt(index);

      SharedPreferences.getInstance().then((prefs) {
        Preferences.setNGNamesRegex(prefs, this.ngs);
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$removedを削除しました")));
    });
  }

  String getTitle() {
    return 'NG Name（正規表現）';
  }
}
