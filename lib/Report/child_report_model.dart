import 'package:flutter/foundation.dart';

// Main response model for the child-report API
class ChildReportResponse {
  final List<ChildReportGroup> reports;

  ChildReportResponse({required this.reports});

  factory ChildReportResponse.fromJson(Map<String, dynamic> json) {
    var list = json['\$values'] as List? ?? [];
    List<ChildReportGroup> reportsList =
    list.map((i) => ChildReportGroup.fromJson(i)).toList();
    return ChildReportResponse(reports: reportsList);
  }

  Map<String, dynamic> toJson() {
    return {
      '\$values': reports.map((v) => v.toJson()).toList(),
    };
  }
}

class ChildReportGroup {
  final int groupId;
  final String groupName;
  final ReportItemList good;
  final ReportItemList notGood;
  final RecommendationList recommendations;

  ChildReportGroup({
    required this.groupId,
    required this.groupName,
    required this.good,
    required this.notGood,
    required this.recommendations,
  });

  factory ChildReportGroup.fromJson(Map<String, dynamic> json) {
    return ChildReportGroup(
      groupId: json['groupId'] as int? ?? 0,
      groupName: json['groupName'] as String? ?? '',
      good: ReportItemList.fromJson(json['good'] as Map<String, dynamic>? ?? { '\$values': [] }),
      notGood: ReportItemList.fromJson(json['notGood'] as Map<String, dynamic>? ?? { '\$values': [] }),
      recommendations: RecommendationList.fromJson(
          json['recommendations'] as Map<String, dynamic>? ?? { '\$values': [] }),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'good': good.toJson(),
      'notGood': notGood.toJson(),
      'recommendations': recommendations.toJson(),
    };
  }
}

class ReportItemList {
  final List<ReportItem> items;

  ReportItemList({required this.items});

  factory ReportItemList.fromJson(Map<String, dynamic> json) {
    var list = json['\$values'] as List? ?? [];
    List<ReportItem> itemsList =
    list.map((i) => ReportItem.fromJson(i)).toList();
    return ReportItemList(items: itemsList);
  }

  Map<String, dynamic> toJson() {
    return {
      '\$values': items.map((v) => v.toJson()).toList(),
    };
  }
}

class ReportItem {
  final String title;
  final String message;
  final int sessionId;

  ReportItem({
    required this.title,
    required this.message,
    required this.sessionId,
  });

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      sessionId: json['sessionId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'sessionId': sessionId,
    };
  }
}

class RecommendationList {
  final List<RecommendationItem> items;

  RecommendationList({required this.items});

  factory RecommendationList.fromJson(Map<String, dynamic> json) {
    var list = json['\$values'] as List? ?? [];
    List<RecommendationItem> itemsList =
    list.map((i) => RecommendationItem.fromJson(i)).toList();
    return RecommendationList(items: itemsList);
  }

  Map<String, dynamic> toJson() {
    return {
      '\$values': items.map((v) => v.toJson()).toList(),
    };
  }
}

class RecommendationItem {
  final String title;
  final String message;
  final int sessionId;

  RecommendationItem({
    required this.title,
    required this.message,
    required this.sessionId,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      sessionId: json['sessionId'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'message': message,
      'sessionId': sessionId,
    };
  }
}