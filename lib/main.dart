import 'favorite_thread_list.dart';
import 'package:flutter/material.dart';
import 'board_list.dart';
import 'general_settings.dart';
import 'preferences.dart';
import 'bottom_navigation_bar.dart' as bnb;

void main() async {
  runApp(B5SViewerApp());
}

class B5SViewerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Preferences.initialize();

    return MaterialApp(
      title: 'B5S Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData.dark(),
      home: AppBarStatelessWidget(),
    );
  }
}

class AppBarStatelessWidget extends StatelessWidget {
  AppBarStatelessWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('B5S Viewer'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '設定',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (BuildContext context) {
                  return GeneralSettingsWidget();
                },
              ));
            },
          ),
        ],
      ),
      body: BottomNavigationStatefulWidget(),
    );
  }
}

class BottomNavigationStatefulWidget extends StatefulWidget {
  BottomNavigationStatefulWidget({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _BottomNavigationStatefulWidgetState createState() =>
      _BottomNavigationStatefulWidgetState();
}

class _BottomNavigationStatefulWidgetState
    extends State<BottomNavigationStatefulWidget> {
  void _onItemTapped(int index) {
    if (index == 0) {
      if (bnb.barWidgets[bnb.selectedIndex - 1] is FavoriteThreadListWidget) {
        ((bnb.barWidgets[bnb.selectedIndex - 1] as FavoriteThreadListWidget).key
                as GlobalKey<FavoriteThreadListState>)
            .currentState
            .getFavoriteThread();
      } else if (bnb.barWidgets[bnb.selectedIndex - 1] is BoardListWidget) {
        ((bnb.barWidgets[bnb.selectedIndex - 1] as BoardListWidget).key
                as GlobalKey<BoardListState>)
            .currentState
            .addNewBoard();
      }
    } else {
      setState(() {
        if (index == 1) {
          bnb.barItems[0] = BottomNavigationBarItem(
            icon: Icon(Icons.refresh),
            label: '更新',
          );
        } else if (index == 2) {
          bnb.barItems[0] = BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: '板追加',
          );
        }
        bnb.selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: bnb.barWidgets.elementAt(bnb.selectedIndex - 1),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: bnb.barItems,
        currentIndex: bnb.selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
