import 'package:json_annotation/json_annotation.dart';

import 'board.dart';

part 'thread.g.dart';

// flutter packages pub run build_runner build
@JsonSerializable()
class Thread {
  @JsonKey(name: 'dat')
  final String dat;

  @JsonKey(name: 'title')
  final String title;
  
  @JsonKey(name: 'count')
  int count;

  @JsonKey(name: 'board')
  Board board;

  Thread(this.dat, this.title, this.count, this.board);

  factory Thread.fromJson(Map<String, dynamic> json) => _$ThreadFromJson(json);
  Map<String, dynamic> toJson() => _$ThreadToJson(this);
}
