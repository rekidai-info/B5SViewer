import 'package:flutter/material.dart';
import 'board_list.dart';
import 'favorite_thread_list.dart';

int selectedIndex = 1;

final List<StatefulWidget> barWidgets = [
  FavoriteThreadListWidget(),
  BoardListWidget(),
];

final List<BottomNavigationBarItem> barItems = <BottomNavigationBarItem>[
  BottomNavigationBarItem(
    icon: Icon(Icons.refresh),
    label: '更新',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.favorite),
    label: 'お気に入り',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.inbox),
    label: '板',
  ),
];