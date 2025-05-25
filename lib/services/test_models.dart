// models/test_models.dart
import 'dart:convert';

// Helper function to decode JSON safely
List<TestDetailDto> testDetailDtoFromJson(String str) => List<TestDetailDto>.from(json.decode(str).map((x) => TestDetailDto.fromJson(x)));

String testDetailDtoToJson(List<TestDetailDto> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TestDetailDto {
  final int id;
  final String question;
  final String imagePath; // تأكد من أن هذا المسار كامل أو ستحتاج لإضافة Base URL
  final int testId;
  final List<TestOptionDto> options;

  TestDetailDto({
    required this.id,
    required this.question,
    required this.imagePath,
    required this.testId,
    required this.options,
  });

  factory TestDetailDto.fromJson(Map<String, dynamic> json) => TestDetailDto(
    id: json["id"] ?? 0, // Provide default value if null
    question: json["question"] ?? "No question text", // Provide default value
    imagePath: json["imagePath"] ?? "", // Provide default value or placeholder path
    testId: json["testId"] ?? 0, // Provide default value
    options: json["options"] == null ? [] : List<TestOptionDto>.from(json["options"].map((x) => TestOptionDto.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "question": question,
    "imagePath": imagePath,
    "testId": testId,
    "options": List<dynamic>.from(options.map((x) => x.toJson())),
  };
}

class TestOptionDto {
  final int id;
  final String option;
  final bool isCorrect;

  TestOptionDto({
    required this.id,
    required this.option,
    required this.isCorrect,
  });

  factory TestOptionDto.fromJson(Map<String, dynamic> json) => TestOptionDto(
    id: json["id"] ?? 0, // Provide default value
    option: json["option"] ?? "No option text", // Provide default value
    isCorrect: json["isCorrect"] ?? false, // Provide default value
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "option": option,
    "isCorrect": isCorrect,
  };
}