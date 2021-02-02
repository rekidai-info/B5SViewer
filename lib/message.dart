import 'package:json_annotation/json_annotation.dart';

import 'thread.dart';

part 'message.g.dart';

// flutter packages pub run build_runner build
@JsonSerializable()
class Message extends Comparable<Message> {
  @JsonKey(name: 'no')
  int no;

  @JsonKey(name: 'name')
  String name;

  @JsonKey(name: 'address')
  String address;

  @JsonKey(name: 'date')
  String date;

  @JsonKey(name: 'text')
  String text;

  @JsonKey(name: 'id')
  String id;

  @JsonKey(name: 'thread')
  Thread thread;

  @JsonKey(name: 'post_no')
  int postNo;

  @JsonKey(name: 'post_count')
  int postCount;

  @JsonKey(name: 'responses')
  List<Message> responses;

  @JsonKey(name: 'response_count')
  int responseCount;

  Message(this.no, this.name, this.address, this.date, this.text, this.id, this.thread, this.postNo, this.postCount, this.responses, this.responseCount);

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  @override
  int compareTo(Message other) {
    return no.compareTo(other.no);
  }
}
