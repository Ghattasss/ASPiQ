import 'package:flutter/material.dart';

//import 'package:gp1/widgets/SectionScreen.dart';

import '../widgets/SectionScreen.dart';

// تأكد من استيراد الملف الذي يحتوي على CategoryScreen

class SkillsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> skills = [
      {
        "title": "التواصل اللفظي",
        "description": "تعليم الطفل التفاعل مع الآخرين باستخدام الكلام."
      },
      {
        "title": "التواصل غير اللفظي",
        "description": "تعليم الطفل استخدام الإيماءات والتعابير للتفاعل."
      },
      {
        "title": "أنشطة اجتماعية",
        "description": "تمارين لتعزيز المهارات الاجتماعية والتفاعل."
      },
      {
        "title": "التعرف على أشخاص",
        "description": "تعلم مهارات بناء العلاقات وفهم الآخرين."
      },
    ];

    return CategoryScreen(title: "تنمية المهارات", items: skills);
  }
}
