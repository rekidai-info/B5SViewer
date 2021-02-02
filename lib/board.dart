import 'package:json_annotation/json_annotation.dart';

part 'board.g.dart';

// flutter packages pub run build_runner build
@JsonSerializable()
class Board {
  @JsonKey(name: 'url')
  final String url;

  @JsonKey(name: 'name')
  final String name;

  const Board(this.url, this.name);

  factory Board.fromJson(Map<String, dynamic> json) => _$BoardFromJson(json);
  Map<String, dynamic> toJson() => _$BoardToJson(this);
}
