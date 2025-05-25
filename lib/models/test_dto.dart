// models/test_dto.dart
import 'dart:convert';

// Helper to decode a list
List<TestDto> testDtoListFromJson(String str) => List<TestDto>.from(json.decode(str).map((x) => TestDto.fromJson(x)));

class TestDto {
  final int id;
  final String? title; // قد يكون مفيدًا للعرض أو التسجيل
  // أضف أي حقول أخرى قد يرجعها الـ API وتكون مفيدة

  TestDto({
    required this.id,
    this.title,
  });

  factory TestDto.fromJson(Map<String, dynamic> json) => TestDto(
    id: json["id"] ?? 0, // يجب أن يكون الـ id موجودًا
    title: json["title"],
  );

  // toJson (إذا احتجت إليه)
  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
  };
}