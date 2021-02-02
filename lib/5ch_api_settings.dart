import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences.dart';

final GlobalKey<FiveChAPISettingsState> _fiveChAPISettingsWidgetKey =
    GlobalKey<FiveChAPISettingsState>(debugLabel: 'FiveChAPISettingsWidget');

class FiveChAPISettingsWidget extends StatefulWidget {
  FiveChAPISettingsWidget({Key key}) : super(key: _fiveChAPISettingsWidgetKey);

  @override
  State<StatefulWidget> createState() {
    return FiveChAPISettingsState();
  }
}

class FiveChAPISettingsState extends State<FiveChAPISettingsWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'FiveChAPISettingsState');
  List<String> ngs;

  @override
  @protected
  @mustCallSuper
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = [
      TextField(
        controller: TextEditingController(text: Preferences.fiveChAPIID),
        decoration: InputDecoration(labelText: 'ID（浪人）'),
        onChanged: (value) {
          SharedPreferences.getInstance().then((prefs) {
            Preferences.set5chAPIID(prefs, value);
            prefs.remove('5ch_api_auth_sid');
            prefs.remove('5ch_api_auth_sid_epoch_sec');
          });
        },
      ),
      TextField(
        controller: TextEditingController(text: Preferences.fiveChAPIPW),
        decoration: InputDecoration(labelText: 'PW（浪人）'),
        onChanged: (value) {
          SharedPreferences.getInstance().then((prefs) {
            Preferences.set5chAPIPW(prefs, value);
            prefs.remove('5ch_api_auth_sid');
            prefs.remove('5ch_api_auth_sid_epoch_sec');
          });
        },
      ),
      TextField(
        controller: TextEditingController(text: Preferences.fiveChAPIHMKey),
        decoration: InputDecoration(labelText: 'HMKey'),
        onChanged: (value) {
          SharedPreferences.getInstance().then((prefs) {
            Preferences.set5chAPIHMKey(prefs, value);
            prefs.remove('5ch_api_auth_sid');
            prefs.remove('5ch_api_auth_sid_epoch_sec');
          });
        },
      ),
      TextField(
        controller: TextEditingController(text: Preferences.fiveChAPIAppKey),
        decoration: InputDecoration(labelText: 'AppKey'),
        onChanged: (value) {
          SharedPreferences.getInstance().then((prefs) {
            Preferences.set5chAPIAppKey(prefs, value);
            prefs.remove('5ch_api_auth_sid');
            prefs.remove('5ch_api_auth_sid_epoch_sec');
          });
        },
      ),
      TextField(
        controller: TextEditingController(text: Preferences.fiveChAPIX2chUA),
        decoration: InputDecoration(labelText: 'X-2ch-UA'),
        onChanged: (value) {
          SharedPreferences.getInstance().then((prefs) {
            Preferences.set5chAPIX2chUA(prefs, value);
            prefs.remove('5ch_api_auth_sid');
            prefs.remove('5ch_api_auth_sid_epoch_sec');
          });
        },
      ),
      TextField(
        controller: TextEditingController(text: Preferences.fiveChAPIUARead),
        decoration: InputDecoration(labelText: 'User-Agent（読み込み時）'),
        onChanged: (value) {
          SharedPreferences.getInstance().then((prefs) {
            Preferences.set5chAPIUARead(prefs, value);
          });
        },
      ),
      TextField(
        controller: TextEditingController(text: Preferences.fiveChAPIUAWrite),
        decoration: InputDecoration(labelText: 'User-Agent（書き込み時）'),
        onChanged: (value) {
          SharedPreferences.getInstance().then((prefs) {
            Preferences.set5chAPIUAWrite(prefs, value);
          });
        },
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('5ch API 設定'),
      ),
      body: Scrollbar(
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: widgets.length,
          itemBuilder: (context, index) {
            return widgets[index];
          },
        ),
      ),
    );
  }
}
