import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'essay.g.dart';

enum EssayStatus {
  draft,
  archived,
}

@JsonSerializable()
class Essay extends Equatable {
  final String id;
  final String title;
  final String content;
  final EssayStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Essay({
    required this.id,
    required this.title,
    required this.content,
    this.status = EssayStatus.draft,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Essay.fromJson(Map<String, dynamic> json) => _$EssayFromJson(json);
  Map<String, dynamic> toJson() => _$EssayToJson(this);

  Essay copyWith({
    String? id,
    String? title,
    String? content,
    EssayStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Essay(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, content, status, createdAt, updatedAt];
}
