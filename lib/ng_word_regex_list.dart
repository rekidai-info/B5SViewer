import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ng_list.dart';
import 'preferences.dart';

final GlobalKey<NGWordRegexListState> _ngWordRegexListWidgetKey = GlobalKey<NGWordRegexListState>(debugLabel: 'NGWordRegexListWidget');

class NGWordRegexListWidget extends NGListWidget {
  NGWordRegexListWidget({Key key }) : super(key: _ngWordRegexListWidgetKey);

  @override
  State<StatefulWidget> createState() {
    return NGWordRegexListState();
  }
}

class NGWordRegexListState extends NGListState {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'NGWordRegexListState');

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
        ngs = Preferences.getNGWordsRegex(prefs);
      });
    });
  }

  @override
  void addNG(String ng) {
    if (!ngs.contains(ng)) {
      SharedPreferences.getInstance().then((prefs) {
        try {
          RegExp(ng, multiLine: true, caseSensitive: false);
          setState(() {
            ngs.add(ng);
            Preferences.setNGWordsRegex(prefs, ngs);
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
        Preferences.setNGWordsRegex(prefs, this.ngs);
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$removedを削除しました")));
    });
  }

  String getTitle() {
    return 'NG Word（正規表現）';
  }
}
