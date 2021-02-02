// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'board.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Board _$BoardFromJson(Map<String, dynamic> json) {
  return Board(
    json['url'] as String,
    json['name'] as String,
  );
}

Map<String, dynamic> _$BoardToJson(Board instance) => <String, dynamic>{
      'url': instance.url,
      'name': instance.name,
    };
