import 'package:flutter/material.dart';

// شاشة الفئة التي تعرض قائمة بالعناصر وتحتوي على نافذة منبثقة للجلسات
class CategoryScreen extends StatelessWidget {
  final String title; // عنوان الفئة
  final List<Map<String, String>>
      items; // قائمة بالعناصر التي تحتوي على عنوان ووصف لكل عنصر

  const CategoryScreen({required this.title, required this.items, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // منع إضافة زر الرجوع الافتراضي
        backgroundColor: Colors.white,
        elevation: 0,
        title: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              title,
              style: TextStyle(
                color: Color(0xff2C73D9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        actions: [
          // زر الرجوع إلى الشاشة السابقة
          IconButton(
            icon: Padding(
              padding: const EdgeInsets.only(right: 16.0, top: 16),
              child: Icon(Icons.arrow_forward_ios, color: Color(0xff2C73D9)),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),

      // بناء قائمة العناصر في الشاشة
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildCard(
                context, items[index]['title']!, items[index]['description']!);
          },
        ),
      ),
    );
  }

  // إنشاء عنصر كرت يعرض عنوان ووصف لكل عنصر
  Widget _buildCard(BuildContext context, String title, String description) {
    return GestureDetector(
      onTap: () {
        _showBottomSheet(
            context, title); // عرض النافذة المنبثقة عند الضغط على الكرت
      },
      child: Card(
        color: Color.fromARGB(255, 219, 231, 250), // لون خلفية الكرت
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // عنوان العنصر في وسط الكرت
              Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff2C73D9),
                  ),
                ),
              ),
              SizedBox(height: 8),
              // وصف العنصر مع اتجاه النص من اليمين لليسار
              Text(
                description,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: Color(0xffA2A2A2).withOpacity(.90),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // عرض النافذة المنبثقة عند الضغط على العنصر
  void _showBottomSheet(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xff2C73D9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // زر الإغلاق في أقصى اليسار
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // عرض قائمة الجلسات في النافذة المنبثقة
              ..._getSessions()
                  .map((session) => _buildSessionItem(session))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  // قائمة تحتوي على أسماء الجلسات
  List<String> _getSessions() {
    return [
      "الجلسة الأولى",
      "الجلسة الثانية",
      "الجلسة الثالثة",
      "الجلسة الرابعة"
    ];
  }

  // إنشاء عنصر للجلسة داخل النافذة المنبثقة
  Widget _buildSessionItem(String session) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
        title: Align(
          alignment: Alignment.centerRight,
          child: Text(
            session,
            style: TextStyle(
              color: Color(0xff2C73D9),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: Icon(Icons.arrow_back_ios_new, color: Color(0xff2C73D9)),
        // السهم في اليسار
        onTap: () {},
      ),
    );
  }
}
