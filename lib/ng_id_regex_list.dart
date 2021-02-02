import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ng_list.dart';
import 'preferences.dart';

final GlobalKey<NGIdRegexListState> _ngIdRegexListWidgetKey =
    GlobalKey<NGIdRegexListState>(debugLabel: 'NGIdRegexListWidget');

class NGIdRegexListWidget extends NGListWidget {
  NGIdRegexListWidget({Key key}) : super(key: _ngIdRegexListWidgetKey);

  @override
  State<StatefulWidget> createState() {
    return NGIdRegexListState();
  }
}

class NGIdRegexListState extends NGListState {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'NGIdRegexListState');

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
        ngs = Preferences.getNGIdsRegex(prefs);
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
            Preferences.setNGIdsRegex(prefs, ngs);
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
        Preferences.setNGIdsRegex(prefs, this.ngs);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("$removedを削除しました")));
    });
  }

  String getTitle() {
    return 'NG ID（正規表現）';
  }
}
