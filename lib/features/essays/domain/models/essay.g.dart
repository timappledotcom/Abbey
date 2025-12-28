// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'essay.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Essay _$EssayFromJson(Map<String, dynamic> json) => Essay(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  status:
      $enumDecodeNullable(_$EssayStatusEnumMap, json['status']) ??
      EssayStatus.draft,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$EssayToJson(Essay instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'status': _$EssayStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$EssayStatusEnumMap = {
  EssayStatus.draft: 'draft',
  EssayStatus.archived: 'archived',
};
