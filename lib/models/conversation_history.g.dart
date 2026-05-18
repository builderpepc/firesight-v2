// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationTurn _$ConversationTurnFromJson(Map<String, dynamic> json) =>
    ConversationTurn(
      role: json['role'] as String,
      content: json['content'] as String,
    );

Map<String, dynamic> _$ConversationTurnToJson(ConversationTurn instance) =>
    <String, dynamic>{
      'role': instance.role,
      'content': instance.content,
    };

ConversationHistory _$ConversationHistoryFromJson(Map<String, dynamic> json) =>
    ConversationHistory(
      turns: (json['turns'] as List<dynamic>?)
          ?.map((e) => ConversationTurn.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ConversationHistoryToJson(
        ConversationHistory instance) =>
    <String, dynamic>{
      'turns': instance.turns,
    };
