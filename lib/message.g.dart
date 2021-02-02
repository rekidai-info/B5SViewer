// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) {
  return Message(
    json['no'] as int,
    json['name'] as String,
    json['address'] as String,
    json['date'] as String,
    json['text'] as String,
    json['id'] as String,
    json['thread'] == null
        ? null
        : Thread.fromJson(json['thread'] as Map<String, dynamic>),
    json['post_no'] as int,
    json['post_count'] as int,
    (json['responses'] as List)
        ?.map((e) =>
            e == null ? null : Message.fromJson(e as Map<String, dynamic>))
        ?.toList(),
    json['response_count'] as int,
  );
}

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'no': instance.no,
      'name': instance.name,
      'address': instance.address,
      'date': instance.date,
      'text': instance.text,
      'id': instance.id,
      'thread': instance.thread,
      'post_no': instance.postNo,
      'post_count': instance.postCount,
      'responses': instance.responses,
      'response_count': instance.responseCount,
    };
