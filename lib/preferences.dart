import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'board.dart';
import 'thread.dart';

class Preferences {
  static String fiveChAPIID = '';
  static String fiveChAPIPW = '';
  static String fiveChAPIHMKey = '';
  static String fiveChAPIAppKey = '';
  static String fiveChAPIX2chUA = '';
  static String fiveChAPIUARead = '';
  static String fiveChAPIUAWrite = '';

  static List<Board> boards = [];
  static List<Thread> threads = [];
  static Map<String, int> threadReadCount = {};
  static Map<String, int> threadScrollIndex = {};
  static Map<String, double> threadScrollIndexLeading = {};
  static List<String> ngIds = [];
  static List<String> ngNames = [];
  static List<String> ngWords = [];
  static List<String> ngIdsRegex = [];
  static List<String> ngNamesRegex = [];
  static List<String> ngWordsRegex = [];

  static void initialize() {
    SharedPreferences.getInstance().then((prefs) {
      get5chAPIID(prefs);
      get5chAPIPW(prefs);
      get5chAPIHMKey(prefs);
      get5chAPIAppKey(prefs);
      get5chAPIX2chUA(prefs);
      get5chAPIUARead(prefs);
      get5chAPIUAWrite(prefs);

      if (hasBoards(prefs)) {
        getBoards(prefs);
      } else {
        setBoards(prefs, []);
      }

      if (hasThreads(prefs)) {
        getThreads(prefs);
      } else {
        setThreads(prefs, []);
      }

      if (hasThreadReadCount(prefs)) {
        getThreadReadCountAll(prefs);
      } else {
        setThreadReadCountAll(prefs, {});
      }

      if (hasThreadScrollIndex(prefs)) {
        getThreadScrollIndexAll(prefs);
      } else {
        setThreadScrollIndexAll(prefs, {});
      }

      if (hasThreadScrollIndexLeading(prefs)) {
        getThreadScrollIndexLeadingAll(prefs);
      } else {
        setThreadScrollIndexLeadingAll(prefs, {});
      }

      if (hasNGIds(prefs)) {
        getNGIds(prefs);
      } else {
        setNGIds(prefs, []);
      }

      if (hasNGNames(prefs)) {
        getNGNames(prefs);
      } else {
        setNGNames(prefs, []);
      }

      if (hasNGWords(prefs)) {
        getNGWords(prefs);
      } else {
        setNGWords(prefs, []);
      }

      if (hasNGIdsRegex(prefs)) {
        getNGIdsRegex(prefs);
      } else {
        setNGIdsRegex(prefs, []);
      }

      if (hasNGNamesRegex(prefs)) {
        getNGNamesRegex(prefs);
      } else {
        setNGNamesRegex(prefs, []);
      }

      if (hasNGWordsRegex(prefs)) {
        getNGWordsRegex(prefs);
      } else {
        setNGWordsRegex(prefs, []);
      }
    });
  }

  static String get5chAPIID(SharedPreferences prefs) {
    Preferences.fiveChAPIID = prefs.getString("5ch_api_auth_id");
    if (Preferences.fiveChAPIID == null) {
      Preferences.fiveChAPIID = '';
    }

    return Preferences.fiveChAPIID;
  }

  static Future<bool> set5chAPIID(SharedPreferences prefs, String id) {
    Preferences.fiveChAPIID = id;
    return prefs.setString("5ch_api_auth_id", id);
  }

  static String get5chAPIPW(SharedPreferences prefs) {
    Preferences.fiveChAPIPW = prefs.getString("5ch_api_auth_pw");
    if (Preferences.fiveChAPIPW == null) {
      Preferences.fiveChAPIPW = '';
    }

    return Preferences.fiveChAPIPW;
  }

  static Future<bool> set5chAPIPW(SharedPreferences prefs, String pw) {
    Preferences.fiveChAPIPW = pw;
    return prefs.setString("5ch_api_auth_pw", pw);
  }

  static String get5chAPIHMKey(SharedPreferences prefs) {
    Preferences.fiveChAPIHMKey = prefs.getString("5ch_api_auth_hmkey");
    if (Preferences.fiveChAPIHMKey == null) {
      Preferences.fiveChAPIHMKey = '';
    }

    return Preferences.fiveChAPIHMKey;
  }

  static Future<bool> set5chAPIHMKey(SharedPreferences prefs, String hmKey) {
    Preferences.fiveChAPIHMKey = hmKey;
    return prefs.setString("5ch_api_auth_hmkey", hmKey);
  }

  static String get5chAPIAppKey(SharedPreferences prefs) {
    Preferences.fiveChAPIAppKey = prefs.getString("5ch_api_auth_appkey");
    if (Preferences.fiveChAPIAppKey == null) {
      Preferences.fiveChAPIAppKey = '';
    }

    return Preferences.fiveChAPIAppKey;
  }

  static Future<bool> set5chAPIAppKey(SharedPreferences prefs, String appKey) {
    Preferences.fiveChAPIAppKey = appKey;
    return prefs.setString("5ch_api_auth_appkey", appKey);
  }

  static String get5chAPIX2chUA(SharedPreferences prefs) {
    Preferences.fiveChAPIX2chUA = prefs.getString("5ch_api_auth_x_2ch_ua");
    if (Preferences.fiveChAPIX2chUA == null) {
      Preferences.fiveChAPIX2chUA = '';
    }

    return Preferences.fiveChAPIX2chUA;
  }

  static Future<bool> set5chAPIX2chUA(SharedPreferences prefs, String x2chUA) {
    Preferences.fiveChAPIX2chUA = x2chUA;
    return prefs.setString("5ch_api_auth_x_2ch_ua", x2chUA);
  }

  static String get5chAPIUARead(SharedPreferences prefs) {
    Preferences.fiveChAPIUARead = prefs.getString("5ch_api_ua_read");
    if (Preferences.fiveChAPIUARead == null) {
      Preferences.fiveChAPIUARead = '';
    }

    return Preferences.fiveChAPIUARead;
  }

  static Future<bool> set5chAPIUARead(SharedPreferences prefs, String uaRead) {
    Preferences.fiveChAPIUARead = uaRead;
    return prefs.setString("5ch_api_ua_read", uaRead);
  }

  static String get5chAPIUAWrite(SharedPreferences prefs) {
    Preferences.fiveChAPIUAWrite = prefs.getString("5ch_api_ua_write");
    if (Preferences.fiveChAPIUAWrite == null) {
      Preferences.fiveChAPIUAWrite = '';
    }

    return Preferences.fiveChAPIUAWrite;
  }

  static Future<bool> set5chAPIUAWrite(SharedPreferences prefs, String uaWrite) {
    Preferences.fiveChAPIUAWrite = uaWrite;
    return prefs.setString("5ch_api_ua_write", uaWrite);
  }

  static bool hasBoards(SharedPreferences prefs) {
    return prefs.containsKey("boards");
  }

  static List<Board> getBoards(SharedPreferences prefs) {
    var pref = prefs.getString('boards');
    if (pref == null) {
      return [];
    }

    var decoded = json.decode(pref);

    if (!(decoded is List)) {
      return [];
    }

    List list = decoded as List;
    List<Board> result = [];

    for (var data in list) {
      var board = Board.fromJson(data);
      result.add(board);
    }

    Preferences.boards = result;

    return Preferences.boards;
  }

  static Future<bool> setBoards(SharedPreferences prefs, List<Board> boards) {
    Preferences.boards = boards;

    List<Map<String, dynamic>> result = [];

    for (var board in boards) {
      result.add(board.toJson());
    }

    return prefs.setString("boards", json.encode(result));
  }

  static Future<bool> removeBoards(SharedPreferences prefs) {
    Preferences.boards = [];

    return prefs.remove("boards");
  }

  static bool hasThreads(SharedPreferences prefs) {
    return prefs.containsKey("threads");
  }

  static List<Thread> getThreads(SharedPreferences prefs) {
    var pref = prefs.getString('threads');
    if (pref == null) {
      return [];
    }

    var decoded = json.decode(pref);

    if (!(decoded is List)) {
      return [];
    }

    List list = decoded as List;
    List<Thread> result = [];

    for (var data in list) {
      var thread = Thread.fromJson(data);
      result.add(thread);
    }

    Preferences.threads = result;

    return Preferences.threads;
  }

  static Future<bool> setThreads(
      SharedPreferences prefs, List<Thread> threads) {
    Preferences.threads = threads;

    List<Map<String, dynamic>> result = [];

    for (var thread in threads) {
      result.add(thread.toJson());
    }

    return prefs.setString("threads", json.encode(result));
  }

  static Future<bool> removeThreads(SharedPreferences prefs) {
    Preferences.threads = [];

    return prefs.remove("threads");
  }

  static bool hasThreadReadCount(SharedPreferences prefs) {
    return prefs.containsKey("thread_read_count");
  }

  static Map<String, int> getThreadReadCountAll(SharedPreferences prefs) {
    var pref = prefs.getString('thread_read_count');
    if (pref == null) {
      return {};
    }

    Preferences.threadReadCount = Map<String, int>.from(json.decode(pref));

    return Preferences.threadReadCount;
  }

  static int getThreadReadCount(SharedPreferences prefs, String threadId) {
    int result = getThreadReadCountAll(prefs)[threadId];

    if (result == null) {
      return 0;
    } else {
      return result;
    }
  }

  static Future<bool> setThreadReadCountAll(
      SharedPreferences prefs, Map<String, int> threadReadCount) {
    Preferences.threadReadCount = threadReadCount;

    return prefs.setString(
        "thread_read_count", json.encode(Preferences.threadReadCount));
  }

  static Future<bool> setThreadReadCount(
      SharedPreferences prefs, String threadId, int count) {
    Preferences.threadReadCount[threadId] = count;

    return prefs.setString(
        "thread_read_count", json.encode(Preferences.threadReadCount));
  }

  static Future<bool> emptyThreadReadCount(SharedPreferences prefs) {
    Preferences.threadReadCount = {};

    return prefs.remove("thread_read_count");
  }

  static Future<bool> removeThreadReadCount(
      SharedPreferences prefs, String threadId) {
    Map<String, int> result = getThreadReadCountAll(prefs);

    if (result == null) {
      return Future<bool>.value(false);
    } else {
      result.remove(threadId);
      Preferences.threadReadCount = result;

      return prefs.setString(
          "thread_read_count", json.encode(Preferences.threadReadCount));
    }
  }

  static bool hasThreadScrollIndex(SharedPreferences prefs) {
    return prefs.containsKey("thread_scroll_index");
  }

  static Map<String, int> getThreadScrollIndexAll(SharedPreferences prefs) {
    var pref = prefs.getString('thread_scroll_index');
    if (pref == null) {
      return {};
    }

    Preferences.threadScrollIndex = Map<String, int>.from(json.decode(pref));

    return Preferences.threadScrollIndex;
  }

  static int getThreadScrollIndex(SharedPreferences prefs, String threadId) {
    int result = getThreadScrollIndexAll(prefs)[threadId];

    if (result == null) {
      return 0;
    } else {
      return result;
    }
  }

  static Future<bool> setThreadScrollIndexAll(
      SharedPreferences prefs, Map<String, int> threadScrollIndex) {
    Preferences.threadScrollIndex = threadScrollIndex;

    return prefs.setString(
        "thread_scroll_index", json.encode(Preferences.threadScrollIndex));
  }

  static Future<bool> setThreadScrollIndex(
      SharedPreferences prefs, String threadId, int scrollIndex) {
    Preferences.threadScrollIndex[threadId] = scrollIndex;

    return prefs.setString(
        "thread_scroll_index", json.encode(Preferences.threadScrollIndex));
  }

  static Future<bool> emptyThreadScrollIndex(SharedPreferences prefs) {
    Preferences.threadScrollIndex = {};

    return prefs.remove("thread_scroll_index");
  }

  static Future<bool> removeThreadScrollIndex(
      SharedPreferences prefs, String threadId) {
    Map<String, int> result = getThreadScrollIndexAll(prefs);

    if (result == null) {
      return Future<bool>.value(false);
    } else {
      result.remove(threadId);
      Preferences.threadScrollIndex = result;

      return prefs.setString(
          "thread_scroll_index", json.encode(Preferences.threadScrollIndex));
    }
  }

  static bool hasThreadScrollIndexLeading(SharedPreferences prefs) {
    return prefs.containsKey("thread_scroll_index_leading");
  }

  static Map<String, double> getThreadScrollIndexLeadingAll(
      SharedPreferences prefs) {
    var pref = prefs.getString('thread_scroll_index_leading');
    if (pref == null) {
      return {};
    }

    Preferences.threadScrollIndexLeading =
        Map<String, double>.from(json.decode(pref));

    return Preferences.threadScrollIndexLeading;
  }

  static double getThreadScrollIndexLeading(
      SharedPreferences prefs, String threadId) {
    double result = getThreadScrollIndexLeadingAll(prefs)[threadId];

    if (result == null) {
      return 0;
    } else {
      return result;
    }
  }

  static Future<bool> setThreadScrollIndexLeadingAll(
      SharedPreferences prefs, Map<String, double> threadScrollIndexLeading) {
    Preferences.threadScrollIndexLeading = threadScrollIndexLeading;

    return prefs.setString("thread_scroll_index_leading",
        json.encode(Preferences.threadScrollIndexLeading));
  }

  static Future<bool> setThreadScrollIndexLeading(
      SharedPreferences prefs, String threadId, double scrollIndexLeading) {
    Preferences.threadScrollIndexLeading[threadId] = scrollIndexLeading;

    return prefs.setString("thread_scroll_index_leading",
        json.encode(Preferences.threadScrollIndexLeading));
  }

  static Future<bool> emptyThreadScrollIndexLeading(SharedPreferences prefs) {
    Preferences.threadScrollIndexLeading = {};

    return prefs.remove("thread_scroll_index_leading");
  }

  static Future<bool> removeThreadScrollIndexLeading(
      SharedPreferences prefs, String threadId) {
    Map<String, double> result = getThreadScrollIndexLeadingAll(prefs);

    if (result == null) {
      return Future<bool>.value(false);
    } else {
      result.remove(threadId);
      Preferences.threadScrollIndexLeading = result;

      return prefs.setString("thread_scroll_index_leading",
          json.encode(Preferences.threadScrollIndexLeading));
    }
  }

  static bool hasNGIds(SharedPreferences prefs) {
    return prefs.containsKey("ng_ids");
  }

  static List<String> getNGIds(SharedPreferences prefs) {
    var pref = prefs.getString('ng_ids');
    if (pref == null) {
      return [];
    }

    var decoded = json.decode(pref);
    if (!(decoded is List)) {
      return [];
    }

    Preferences.ngIds = decoded.cast<String>();

    return Preferences.ngIds;
  }

  static Future<bool> setNGIds(SharedPreferences prefs, List<String> ngIds) {
    Preferences.ngIds = ngIds;

    return prefs.setString("ng_ids", json.encode(ngIds));
  }

  static Future<bool> removeNGIds(SharedPreferences prefs) {
    Preferences.ngIds = [];

    return prefs.remove("ng_ids");
  }

  static bool hasNGNames(SharedPreferences prefs) {
    return prefs.containsKey("ng_names");
  }

  static List<String> getNGNames(SharedPreferences prefs) {
    var pref = prefs.getString('ng_names');
    if (pref == null) {
      return [];
    }

    var decoded = json.decode(pref);
    if (!(decoded is List)) {
      return [];
    }

    Preferences.ngNames = decoded.cast<String>();

    return Preferences.ngNames;
  }

  static Future<bool> setNGNames(
      SharedPreferences prefs, List<String> ngNames) {
    Preferences.ngNames = ngNames;

    return prefs.setString("ng_names", json.encode(ngNames));
  }

  static Future<bool> removeNGNames(SharedPreferences prefs) {
    Preferences.ngNames = [];

    return prefs.remove("ng_names");
  }

  static bool hasNGWords(SharedPreferences prefs) {
    return prefs.containsKey("ng_words");
  }

  static List<String> getNGWords(SharedPreferences prefs) {
    var pref = prefs.getString('ng_words');
    if (pref == null) {
      return [];
    }

    var decoded = json.decode(pref);
    if (!(decoded is List)) {
      return [];
    }

    Preferences.ngWords = decoded.cast<String>();

    return Preferences.ngWords;
  }

  static Future<bool> setNGWords(
      SharedPreferences prefs, List<String> ngWords) {
    Preferences.ngWords = ngWords;

    return prefs.setString("ng_words", json.encode(ngWords));
  }

  static Future<bool> removeNGWords(SharedPreferences prefs) {
    Preferences.ngWords = [];

    return prefs.remove("ng_words");
  }

    static bool hasNGIdsRegex(SharedPreferences prefs) {
    return prefs.containsKey("ng_ids_regex");
  }

  static List<String> getNGIdsRegex(SharedPreferences prefs) {
    var pref = prefs.getString('ng_ids_regex');
    if (pref == null) {
      return [];
    }

    var decoded = json.decode(pref);
    if (!(decoded is List)) {
      return [];
    }

    Preferences.ngIdsRegex = decoded.cast<String>();

    return Preferences.ngIdsRegex;
  }

  static Future<bool> setNGIdsRegex(SharedPreferences prefs, List<String> ngIdsRegex) {
    Preferences.ngIdsRegex = ngIdsRegex;

    return prefs.setString("ng_ids_regex", json.encode(ngIdsRegex));
  }

  static Future<bool> removeNGIdsRegex(SharedPreferences prefs) {
    Preferences.ngIdsRegex = [];

    return prefs.remove("ng_ids_regex");
  }

  static bool hasNGNamesRegex(SharedPreferences prefs) {
    return prefs.containsKey("ng_names_regex");
  }

  static List<String> getNGNamesRegex(SharedPreferences prefs) {
    var pref = prefs.getString('ng_names_regex');
    if (pref == null) {
      return [];
    }

    var decoded = json.decode(pref);
    if (!(decoded is List)) {
      return [];
    }

    Preferences.ngNamesRegex = decoded.cast<String>();

    return Preferences.ngNamesRegex;
  }

  static Future<bool> setNGNamesRegex(
      SharedPreferences prefs, List<String> ngNamesRegex) {
    Preferences.ngNamesRegex = ngNamesRegex;

    return prefs.setString("ng_names_regex", json.encode(ngNamesRegex));
  }

  static Future<bool> removeNGNamesRegex(SharedPreferences prefs) {
    Preferences.ngNamesRegex = [];

    return prefs.remove("ng_names_regex");
  }

  static bool hasNGWordsRegex(SharedPreferences prefs) {
    return prefs.containsKey("ng_words_regex");
  }

  static List<String> getNGWordsRegex(SharedPreferences prefs) {
    var pref = prefs.getString('ng_words_regex');
    if (pref == null) {
      return [];
    }

    var decoded = json.decode(pref);
    if (!(decoded is List)) {
      return [];
    }

    Preferences.ngWordsRegex = decoded.cast<String>();

    return Preferences.ngWordsRegex;
  }

  static Future<bool> setNGWordsRegex(
      SharedPreferences prefs, List<String> ngWordsRegex) {
    Preferences.ngWordsRegex = ngWordsRegex;

    return prefs.setString("ng_words_regex", json.encode(ngWordsRegex));
  }

  static Future<bool> removeNGWordsRegex(SharedPreferences prefs) {
    Preferences.ngWordsRegex = [];

    return prefs.remove("ng_words_regex");
  }
}

Future<bool> confirm(BuildContext context) async {
  return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('本当によろしいですか？'),
          actions: <Widget>[
            TextButton(
              child: new Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: new Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            )
          ],
        );
      });
}

Future<String> askNewItem(BuildContext context, String title, String label,
    TextInputType keyboardType) async {
  String search;

  return await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: TextEditingController(),
            decoration: InputDecoration(labelText: label),
            keyboardType: keyboardType,
            onChanged: (value) {
              search = value;
            },
            onSubmitted: (value) {
              search = value;
              Navigator.of(context).pop(search);
            },
          ),
        ]),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop(search);
            },
          )
        ],
      );
    }
  );
}
