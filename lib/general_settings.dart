import 'package:flutter/material.dart';

import '5ch_api_settings.dart';
import 'ng_id_list.dart';
import 'ng_id_regex_list.dart';
import 'ng_name_list.dart';
import 'ng_name_regex_list.dart';
import 'ng_word_list.dart';
import 'ng_word_regex_list.dart';

class GeneralSettingsWidget extends StatefulWidget {
  const GeneralSettingsWidget({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GeneralSettingsState();
  }
}

class _GeneralSettingsState extends State<GeneralSettingsWidget> {
  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [
      ListTile(
        title: Text('5ch API 設定'),
        trailing: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return FiveChAPISettingsWidget();
            },
          ));
        }
      ),
      Divider(),
      ListTile(
        title: Text('NG ID'),
        trailing: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return NGIdListWidget();
            },
          ));
        }
      ),
      Divider(),
      ListTile(
        title: Text('NG Name'),
        trailing: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return NGNameListWidget();
            },
          ));
        }
      ),
      Divider(),
      ListTile(
        title: Text('NG Word'),
        trailing: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return NGWordListWidget();
            },
          ));
        }
      ),
      Divider(),
      ListTile(
        title: Text('NG ID（正規表現）'),
        trailing: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return NGIdRegexListWidget();
            },
          ));
        }
      ),
      Divider(),
      ListTile(
        title: Text('NG Name（正規表現）'),
        trailing: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return NGNameRegexListWidget();
            },
          ));
        }
      ),
      Divider(),
      ListTile(
        title: Text('NG Word（正規表現）'),
        trailing: Icon(Icons.keyboard_arrow_right, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) {
              return NGWordRegexListWidget();
            },
          ));
        }
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('設定'),
      ),
      body: Container(
        child: Scrollbar(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: widgets.length,
            itemBuilder: (context, index) {
              return widgets[index];
            },
          ),
        ),
      ),
    );
  }
}
