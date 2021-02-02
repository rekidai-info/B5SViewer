// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Thread _$ThreadFromJson(Map<String, dynamic> json) {
  return Thread(
    json['dat'] as String,
    json['title'] as String,
    json['count'] as int,
    json['board'] == null
        ? null
        : Board.fromJson(json['board'] as Map<String, dynamic>),
  );
}

Map<String, dynamic> _$ThreadToJson(Thread instance) => <String, dynamic>{
      'dat': instance.dat,
      'title': instance.title,
      'count': instance.count,
      'board': instance.board,
    };
