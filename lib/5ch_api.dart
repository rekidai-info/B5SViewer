import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:charset_converter/charset_converter.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:euc/euc.dart';
import 'package:euc/jis.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'board.dart';
import 'message.dart';
import 'preferences.dart';
import 'thread.dart';

Future<String> auth(Thread thread) async {
  if (thread.board.url.contains('5ch')) {
    final prefs = await SharedPreferences.getInstance();

    final String appKey = Preferences.get5chAPIAppKey(prefs);
    final Hmac hmacSha256 =
        Hmac(sha256, utf8.encode(Preferences.get5chAPIHMKey(prefs)));
    final String sidCache = prefs.getString('5ch_api_auth_sid');
    final int sidCacheSec = prefs.getInt('5ch_api_auth_sid_epoch_sec');
    final int nowSec = (DateTime.now().millisecondsSinceEpoch / 1000).round();

    if (sidCache != null &&
        sidCacheSec != null &&
        (nowSec - sidCacheSec) < 86400) {
      return sidCache;
    }

    const CT = '1234567890';
    var digest = hmacSha256.convert(utf8.encode(appKey + CT));
    var resp = await http.post(Uri.https('api.5ch.net', '/v1/auth/'), headers: {
      'User-Agent': '',
      'X-2ch-UA': Preferences.fiveChAPIX2chUA,
      'Content-Type': 'application/x-www-form-urlencoded',
    }, body: {
      'ID': Preferences.get5chAPIID(prefs) == null ? '' : Preferences.get5chAPIID(prefs).trim(),
      'PW': Preferences.get5chAPIPW(prefs) == null ? '' : Preferences.get5chAPIPW(prefs).trim(),
      'KY': appKey,
      'CT': CT,
      'HB': digest.toString(),
    }).timeout(Duration(milliseconds: 8000));

    if (resp.body.startsWith('ng')) {
      throw (resp.body);
    }
    if (!resp.body.contains(':')) {
      throw (resp.body);
    }

    final String sid = resp.body.split(':')[1];

    prefs.setString('5ch_api_auth_sid', sid);
    prefs.setInt('5ch_api_auth_sid_epoch_sec', nowSec);

    return sid;
  } else {
    return null;
  }
}

final _gochServerBoardRegex = RegExp(r'^https?://(.+).5ch.net/(.+)/$',
    multiLine: false, caseSensitive: false);
final _anchorRegex =
    RegExp(r'<a.+?>>>(\d+)</a>', multiLine: false, caseSensitive: false);
final _anchorMultiRegex =
    RegExp(r'<a.+?>>>(\d+)-(\d+)</a>', multiLine: false, caseSensitive: false);
final _anchorRegex2 =
    RegExp(r'>>(\d+)', multiLine: false, caseSensitive: false);
final _anchorMultiRegex2 =
    RegExp(r'>>(\d+)-(\d+)', multiLine: false, caseSensitive: false);
final _charRefRegex =
    RegExp(r'&#(\d+);', multiLine: false, caseSensitive: false);

Future<List<Message>> dat(Thread thread, String sid) async {
  List<Message> result = [];

  if (thread.board.url.contains("5ch")) {
    final match = _gochServerBoardRegex.firstMatch(thread.board.url);
    final server = match.group(1);
    final board = match.group(2);

    final String appKey = Preferences.fiveChAPIAppKey;
    final Hmac hmacSha256 =
        Hmac(sha256, utf8.encode(Preferences.fiveChAPIHMKey));
    var path =
        '/v1/$server/$board/${thread.dat.substring(0, thread.dat.length - ".dat".length)}';
    var message = "$path$sid$appKey";
    var hobo = hmacSha256.convert(utf8.encode(message));

    var resp = await http.post(Uri.https('api.5ch.net', path), headers: {
      'User-Agent': Preferences
          .fiveChAPIUARead,
      'Connection': 'close',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept-Encoding': 'gzip',
    }, body: {
      'sid': sid,
      'hobo': hobo.toString(),
      'appkey': appKey,
    }).timeout(Duration(milliseconds: 8000));

    final lines = await decodeJIS(resp.bodyBytes);
    int no = 1;

    for (String line in LineSplitter().convert(lines)) {
      final columns = line.split('<>');
      final dateAndId = columns[2]
          .replaceAll("<b>", "")
          .replaceAll("</b>", "")
          .replaceAll("<br>", "\n");
      final dateAndIdList = dateAndId.split("ID:");

      String date = "";
      if (dateAndIdList.length >= 1) {
        date = dateAndIdList[0];
      }

      String id = "";
      if (dateAndIdList.length >= 2) {
        id = dateAndIdList[1];
      }

      final message = Message(
        no++,
        columns.length > 0 ? columns[0]
            .replaceAll("<b>", "")
            .replaceAll("</b>", "")
            .replaceAll("<br>", "\n") : "",
        columns.length > 1 ? columns[1]
            .replaceAll("<b>", "")
            .replaceAll("</b>", "")
            .replaceAll("<br>", "\n") : "",
        date.trim(),
        columns.length > 3 ? columns[3]
            .replaceAll("<b>", "")
            .replaceAll("</b>", "")
            .replaceAll("<br>", "\n")
            .replaceAll("&gt;", ">")
            .replaceAll("&lt;", "<")
            .replaceAll("&quot;", '"')
            .replaceAll("&amp;", "&") : "",
        id.trim(),
        thread,
        0,
        0,
        [],
        0,
      );

      if (message.text.contains('&#')) {
        message.text = message.text.replaceAllMapped(
            _charRefRegex,
            (match) =>
                String.fromCharCode(int.parse(match.group(1), radix: 10)));
      }
      if (message.text.contains('<a') || message.text.contains('<A')) {
        message.text = message.text
            .replaceAllMapped(_anchorMultiRegex,
                (match) => '>>${match.group(1)}-${match.group(2)}')
            .replaceAllMapped(_anchorRegex, (match) => '>>${match.group(1)}');
      }

      result.add(message);
    }
  } else if (thread.board.url.contains("shitaraba")) {
    final index = thread.board.url.substring(8).indexOf('/') + 8;
    final board = thread.board.url
        .substring(index + 1, thread.board.url.length - 1);
    final url = thread.board.url.substring(0, index) +
        '/bbs/rawmode.cgi/' +
        board +
        '/' +
        thread.dat.substring(0, thread.dat.length - ".cgi".length);

    var resp = await http.get(Uri.parse(url), headers: {
      'User-Agent': Preferences
          .fiveChAPIUARead,
      'Connection': 'close',
      'Accept-Encoding': 'gzip',
    }).timeout(Duration(milliseconds: 8000));

    final lines = await decodeEucJP(resp.bodyBytes);

    for (String line in LineSplitter().convert(lines)) {
      final columns = line.split('<>');
      final message = Message(
        int.tryParse(columns.length > 0 ? columns[0] : "", radix: 10) ?? 0,
        columns.length > 1 ? columns[1]
            .replaceAll("<b>", "")
            .replaceAll("</b>", "")
            .replaceAll("<br>", "\n") : "",
        columns.length > 2 ? columns[2]
            .replaceAll("<b>", "")
            .replaceAll("</b>", "")
            .replaceAll("<br>", "\n") : "",
        columns.length > 3 ? columns[3]
            .replaceAll("<b>", "")
            .replaceAll("</b>", "")
            .replaceAll("<br>", "\n") : "",
        columns.length > 4 ? columns[4]
            .replaceAll("<b>", "")
            .replaceAll("</b>", "")
            .replaceAll("<br>", "\n")
            .replaceAll("&gt;", ">")
            .replaceAll("&lt;", "<")
            .replaceAll("&quot;", '"')
            .replaceAll("&amp;", "&") : "",
        columns.length > 6 ? columns[6] : "",
        thread,
        0,
        0,
        [],
        0,
      );

      if (message.text.contains('&#')) {
        message.text = message.text.replaceAllMapped(
            _charRefRegex,
            (match) =>
                String.fromCharCode(int.parse(match.group(1), radix: 10)));
      }
      if (message.text.contains('<a') || message.text.contains('<A')) {
        message.text = message.text
            .replaceAllMapped(_anchorMultiRegex,
                (match) => '>>${match.group(1)}-${match.group(2)}')
            .replaceAllMapped(_anchorRegex, (match) => '>>${match.group(1)}');
      }

      result.add(message);
    }
  } else {
    // 2ch.sc or 2ch.sc compatible
    var url = '';

    if (thread.board.url.endsWith('/')) {
      url = thread.board.url + 'dat/' + thread.dat;
    } else {
      url = thread.board.url + '/dat/' + thread.dat;
    }

    var resp = await http.get(Uri.parse(url), headers: {
      'User-Agent': Preferences
          .fiveChAPIUARead,
      'Connection': 'close',
      'Accept-Encoding': 'gzip',
    }).timeout(Duration(milliseconds: 8000));

    final lines = await decodeJIS(resp.bodyBytes);
    int no = 1;

    for (String line in LineSplitter().convert(lines)) {
      final columns = line.split('<>');
      final dateAndId = columns[2]
          .replaceAll("<b>", "")
          .replaceAll("</b>", "")
          .replaceAll("<br>", "\n");
      final dateAndIdList = dateAndId.split("ID:");

      String date = "";
      if (dateAndIdList.length >= 1) {
        date = dateAndIdList[0];
      }

      String id = "";
      if (dateAndIdList.length >= 2) {
        id = dateAndIdList[1];
      }

      final message = Message(
        no++,
        columns[0]
            .replaceAll("<b>", "")
            .replaceAll("</b>", "")
            .replaceAll("<br>", "\n"),
        columns[1]
            .replaceAll("<b>", "")
            .replaceAll("</b>", "")
            .replaceAll("<br>", "\n"),
        date.trim(),
        columns[3]
            .replaceAll("<b>", "")
            .replaceAll("</b>", "")
            .replaceAll("<br>", "\n")
            .replaceAll("&gt;", ">")
            .replaceAll("&lt;", "<")
            .replaceAll("&quot;", '"')
            .replaceAll("&amp;", "&"),
        id.trim(),
        thread,
        0,
        0,
        [],
        0,
      );

      if (message.text.contains('&#')) {
        message.text = message.text.replaceAllMapped(
            _charRefRegex,
            (match) =>
                String.fromCharCode(int.parse(match.group(1), radix: 10)));
      }
      if (message.text.contains('<a') || message.text.contains('<A')) {
        message.text = message.text
            .replaceAllMapped(_anchorMultiRegex,
                (match) => '>>${match.group(1)}-${match.group(2)}')
            .replaceAllMapped(_anchorRegex, (match) => '>>${match.group(1)}');
      }

      result.add(message);
    }
  }

  {
    // ID毎の投稿数カウント
    final idCount = Map<String, int>();

    for (var message in result) {
      if (idCount[message.id] == null) {
        idCount[message.id] = 1;
      } else {
        idCount[message.id]++;
      }

      message.postNo = idCount[message.id];
    }

    for (var message in result) {
      message.postCount = idCount[message.id];
    }
  }

  {
    // 投稿へのレスの集計
    for (var message in result) {
      if (!message.text.contains('>>')) {
        continue;
      }

      var matches = _anchorMultiRegex2.allMatches(message.text);

      if (matches == null || matches.isEmpty) {
        matches = _anchorRegex2.allMatches(message.text);

        if (matches == null || matches.isEmpty) {
          continue;
        } else {
          for (Match match in matches) {
            int index = int.parse(match.group(1).trim(), radix: 10);
            Message responsed = findMessage(result, index);

            if (responsed != null) {
              if (responsed.responseCount == null ||
                  responsed.responseCount <= 0) {
                responsed.responseCount = 1;
              } else {
                responsed.responseCount++;
              }

              responsed.responses.add(message);
            }
          }
        }
      } else {
        for (Match match in matches) {
          int begin = int.parse(match.group(1).trim(), radix: 10);
          int end = int.parse(match.group(2).trim(), radix: 10);

          if (begin > end) {
            final tmp = begin;
            begin = end;
            end = tmp;
          }

          for (int i = begin; i <= end; ++i) {
            Message responsed = findMessage(result, i);

            if (responsed != null) {
              if (responsed.responseCount == null ||
                  responsed.responseCount <= 0) {
                responsed.responseCount = 1;
              } else {
                responsed.responseCount++;
              }

              responsed.responses.add(message);
            }
          }
        }
      }
    }
  }

  return result;
}

Future<List<Thread>> subject(Board board) async {
  var resp = await http.get(Uri.parse(board.url + "subject.txt"), headers: {
    'User-Agent': Preferences
        .fiveChAPIUARead,
    'Connection': 'close',
    'Accept-Encoding': 'gzip',
    'Sec-Fetch-Dest': 'document',
  }).timeout(Duration(milliseconds: 8000));
  List<Thread> result = [];
  String lines;

  if (board.url.contains('5ch')) {
    lines = await decodeJIS(resp.bodyBytes);
  } else if (board.url.contains('shitaraba')) {
    lines = await decodeEucJP(resp.bodyBytes);
  } else {
    lines = await decodeJIS(resp.bodyBytes);
  }

  for (String line in LineSplitter().convert(lines)) {
    List<String> columns;

    if (board.url.contains('5ch')) {
      columns = line.split('<>');
    } else if (board.url.contains('shitaraba')) {
      columns = line.split(',');
    } else {
      columns = line.split('<>');
    }

    if (columns.length < 2) {
      throw Exception(resp.body);
    }

    var count = 0;
    var title = columns[1];
    var beginIndex = title.lastIndexOf('(');
    var endIndex = title.lastIndexOf(')');
    if (beginIndex >= 0) {
      if (endIndex >= 0) {
        var countStr = title.substring(beginIndex + 1, endIndex);
        count = int.tryParse(countStr, radix: 10) ?? 0;
      }
      title = title.substring(0, beginIndex).trimRight();
    }

    result.add(Thread(columns[0], title, count, board));
  }

  return result;
}

Future<http.Response> bbs(Thread thread, String from, String mail, String message, String sid) async {
  if (thread.board.url.contains("5ch")) {
    final match = _gochServerBoardRegex.firstMatch(thread.board.url);
    final server = match.group(1);
    final board = match.group(2);
    final body = {
      'bbs': board,
      'key': thread.dat.substring(0, thread.dat.length - ".dat".length),
      'time': '1',
      'FROM': from,
      'mail': mail,
      'MESSAGE': message,
      'submit': '書き込む',
    };

    if (Preferences.fiveChAPIID != null &&
        Preferences.fiveChAPIID.length > 0 &&
        Preferences.fiveChAPIPW != null &&
        Preferences.fiveChAPIPW.length > 0 &&
        Preferences.fiveChAPIID.trim().length > 0 &&
        Preferences.fiveChAPIPW.trim().length > 0) {
      body['sid'] = sid;
    }

    return http.post(Uri.https('$server.5ch.net', '/test/bbs.cgi'), headers: {
      'User-Agent': Preferences
          .fiveChAPIUAWrite,
      'Referer': thread.board.url,
      'Connection': 'close',
      'Content-Type': 'application/x-www-form-urlencoded',
      'Accept-Encoding': 'gzip',
      'Cookie': 'yuki=akari',
    }, body: body).timeout(Duration(milliseconds: 10000));
  } else if (thread.board.url.contains("shitaraba")) {
    final index = thread.board.url.substring(8).indexOf('/') + 8;
    final board = thread.board.url
        .substring(index + 1, thread.board.url.length - 1); // game/60785
    final url = thread.board.url.substring(0, index) +
        '/bbs/write.cgi/' +
        board +
        '/' +
        thread.dat.substring(0, thread.dat.length - ".cgi".length) +
        '/';
    final body = 'DIR=${board.split('/')[0]}&' +
        'BBS=${board.split('/')[1]}&' +
        'KEY=${thread.dat.substring(0, thread.dat.length - ".cgi".length)}&' +
        'NAME=${percent.encode(await encodeEucJP(from))}&' +
        'MAIL=${percent.encode(await encodeEucJP(mail))}&' +
        'MESSAGE=${percent.encode(await encodeEucJP(message))}';

    return http
        .post(Uri.parse(url),
            headers: {
              'User-Agent': Preferences
                  .fiveChAPIUAWrite,
              'Referer': thread.board.url,
              'Connection': 'close',
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept-Encoding': 'gzip',
            },
            body: body)
        .timeout(Duration(milliseconds: 10000));
  } else {
    var url = thread.board.url;
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    var index = url.lastIndexOf('/');
    var board = url.substring(index + 1);
    url = url.substring(0, index);
    final body = 'bbs=$board&' +
        'key=${thread.dat.substring(0, thread.dat.length - ".dat".length)}&' +
        'time=1&' +
        'FROM=${percent.encode(await encodeJIS(from))}&' +
        'mail=${percent.encode(await encodeJIS(mail))}&' +
        'MESSAGE=${percent.encode(await encodeJIS(message))}&' +
        'submit=${percent.encode(await encodeJIS("書き込む"))}';

    return http
        .post(Uri.parse('$url/test/bbs.cgi'),
            headers: {
              'User-Agent': Preferences
                  .fiveChAPIUAWrite,
              'Referer': thread.board.url,
              'Connection': 'close',
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept-Encoding': 'gzip',
            },
            body: body)
        .timeout(Duration(milliseconds: 10000));
  }
}

final _gochThreadTitleRegex =
    RegExp(r'<h1 class="title">(.+)\n', multiLine: true, caseSensitive: true);
final _shitarabaThreadTitleRegex = RegExp(r'<h1 class="thread-title">(.+)</h1>',
    multiLine: true, caseSensitive: true);
final _nichThreadTitleRegex =
    RegExp(r'<title>(.+)</title>', multiLine: true, caseSensitive: true);

Future<String> getThreadTitle(Thread thread) async {
  String url = getThreadUrl(thread, '/l1');

  if (thread.board.url.contains("5ch")) {
    var resp = await http.get(Uri.parse(url), headers: {
      'User-Agent': Preferences
          .fiveChAPIUARead,
      'Connection': 'close',
      'Accept-Encoding': 'gzip',
    }).timeout(Duration(milliseconds: 8000));

    final match =
        _gochThreadTitleRegex.firstMatch(await decodeJIS(resp.bodyBytes));
    final title = match.group(1);

    return title;
  } else if (thread.board.url.contains("shitaraba")) {
    var resp = await http.get(Uri.parse(url), headers: {
      'User-Agent': Preferences
          .fiveChAPIUARead,
      'Connection': 'close',
      'Accept-Encoding': 'gzip',
    }).timeout(Duration(milliseconds: 8000));

    final match = _shitarabaThreadTitleRegex
        .firstMatch(await decodeEucJP(resp.bodyBytes));
    final title = match.group(1);

    return title;
  } else if (thread.board.url.contains("2ch")) {
    var resp = await http.get(Uri.parse(url.replaceAll('read.cgi', 'read.so')), headers: {
      'User-Agent': Preferences
          .fiveChAPIUARead,
      'Connection': 'close',
      'Accept-Encoding': 'gzip',
    }).timeout(Duration(milliseconds: 8000));

    final match =
        _nichThreadTitleRegex.firstMatch(await decodeJIS(resp.bodyBytes));
    final title = match.group(1);

    return title;
  } else {
    return "";
  }
}

String getThreadUrl(Thread thread, String suffix) {
  if (thread.board.url.contains("shitaraba")) {
    final index = thread.board.url.substring(8).indexOf('/') + 8;
    final board = thread.board.url
        .substring(index + 1, thread.board.url.length - 1);
    final url = thread.board.url.substring(0, index) +
        '/bbs/read.cgi/' +
        board +
        '/' +
        thread.dat.substring(0, thread.dat.length - ".cgi".length) +
        suffix;

    return url;
  } else {
    final index = thread.board.url.substring(8).indexOf('/') + 8;
    final board = thread.board.url
        .substring(index + 1, thread.board.url.length - 1);
    final url = thread.board.url.substring(0, index) +
        '/test/read.cgi/' +
        board +
        '/' +
        thread.dat.substring(0, thread.dat.length - ".dat".length) +
        suffix;

    return url;
  }
}

void openThread(Thread thread) {
  launch(getThreadUrl(thread, '/l50'));
}

Message findMessage(List<Message> messages, int no) {
  Message target =
      Message(no, null, null, null, null, null, null, null, null, null, null);
  int searched = binarySearch(messages, target);

  if (searched < 0) {
    return null;
  }

  return messages[searched];
}

Future<Uint8List> encodeJIS(String input) async {
  if (input == null) {
    return Future<Uint8List>.value(null);
  }
  if (input.length <= 0) {
    return Future<Uint8List>.value(Uint8List(0));
  }

  if (Platform.isIOS || Platform.isAndroid) {
    return CharsetConverter.encode('cp932', input).then((result) {
      if (result == null || result.length <= 0) {
        return Uint8List.fromList(ShiftJIS().encode(input));
      } else {
        return result;
      }
    }).catchError((e, stackTrace) {
      return Uint8List.fromList(ShiftJIS().encode(input));
    });
  } else {
    return Uint8List.fromList(ShiftJIS().encode(input));
  }
}

Future<Uint8List> encodeEucJP(String input) async {
  if (input == null) {
    return Future<Uint8List>.value(null);
  }
  if (input.length <= 0) {
    return Future<Uint8List>.value(Uint8List(0));
  }

  if (Platform.isIOS || Platform.isAndroid) {
    return CharsetConverter.encode('euc-jp', input).then((result) {
      if (result == null || result.length <= 0) {
        return Uint8List.fromList(EucJP().encode(input));
      } else {
        return result;
      }
    }).catchError((e, stackTrace) {
      return Uint8List.fromList(EucJP().encode(input));
    });
  } else {
    return Uint8List.fromList(EucJP().encode(input));
  }
}

Future<String> decodeJIS(Uint8List input) async {
  if (input == null) {
    return Future<String>.value(null);
  }
  if (input.length <= 0) {
    return Future<String>.value("");
  }

  if (Platform.isIOS || Platform.isAndroid) {
    return CharsetConverter.decode('cp932', input).then((result) {
      if (result == null || result.length <= 0) {
        return JISDecoder().convert(input.toList(growable: false));
      } else {
        return result;
      }
    }).catchError((e, stackTrace) {
      return JISDecoder().convert(input.toList(growable: false));
    });
  } else {
    return JISDecoder().convert(input.toList(growable: false));
  }
}

Future<String> decodeEucJP(Uint8List input) async {
  if (input == null) {
    return Future<String>.value(null);
  }
  if (input.length <= 0) {
    return Future<String>.value("");
  }

  if (Platform.isIOS || Platform.isAndroid) {
    return CharsetConverter.decode('euc-jp', input).then((result) {
      if (result == null || result.length <= 0) {
        return EucJPDecoder().convert(input.toList(growable: false));
      } else {
        return result;
      }
    }).catchError((e, stackTrace) {
      return EucJPDecoder().convert(input.toList(growable: false));
    });
  } else {
    return EucJPDecoder().convert(input.toList(growable: false));
  }
}
