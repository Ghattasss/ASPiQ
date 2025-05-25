import 'package:flutter/material.dart';
import 'package:myfinalpro/login/login_view.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: OnboardingScreen(),
  ));
}

// شاشة الـ Onboarding (الشاشة الترحيبية)
class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller =
  PageController(); // للتحكم في الانتقال بين الصفحات
  int _currentIndex = 0; // لتتبع الصفحة الحالية

  // قائمة الصفحات التي تحتوي على المحتوى (العنوان، الوصف، والصورة)
  final List<Map<String, String>> _pages = [
    {
      "title": " ASPIQ!مرحبًا بك في ",
      "subtitle":
      "نساعد الأطفال على تعلم وفهم المشاعر وتطوير مهاراتهم الاجتماعية بطريقة ممتعة ومبتكرة",
      "image": "assets/images/Group (1).png",
    },
    {
      "title": "خطط مخصصة لكل طفل",
      "subtitle": "كل طفل لديه خطة تدريبية مصممة خصيصًا لاحتياجاته",
      "image": "assets/images/amico.png",
    },
    {
      "title": "تابع تقدم طفلك",
      "subtitle": "تقارير تفصيلية تساعدك على متابعة المهارات التي يتعلمها طفلك",
      "image": "assets/images/Frame 1000006726.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    //final screenWidth = MediaQuery.of(context).size.width;
    //final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // تصميم الخلفية العلوية المنحنية
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: SemiCircleClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.75,
                color: Color(0xFFE3EBF8).withOpacity(0.2),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              // زر "تخطي" في أعلى اليمين (يظهر إلا في الصفحة الأخيرة)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _currentIndex == _pages.length - 1
                      ? SizedBox() // إخفاء زر "تخطي" في الصفحة الأخيرة
                      : TextButton(
                    onPressed: () {
                      _controller.jumpToPage(_pages.length - 1);
                    },
                    child: Text(
                      "تخطي",
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xffA2A2A2),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              // عرض محتوى الـ Onboarding داخل PageView
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  reverse: true,
                  // ينعكس الاتجاه ليتناسب مع اللغة العربية
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return OnboardingPage(
                      title: _pages[index]["title"]!,
                      subtitle: _pages[index]["subtitle"]!,
                      image: _pages[index]["image"]!,
                      controller: _controller,
                      pageCount: _pages.length,
                    );
                  },
                ),
              ),
              // عناصر التحكم السفلية (زر التالي، زر العودة، والمؤشر)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 44.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر "ابدأ" يظهر في الصفحة الأخيرة فقط
                    _currentIndex == _pages.length - 1
                        ? ElevatedButton(
                      onPressed: () {
                        // الانتقال إلى الصفحة الرئيسية بعد الانتهاء من Onboarding
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginView()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2C73D9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        "ابدأ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                    // زر "التالي" للتنقل بين الصفحات
                        : CircleAvatar(
                      backgroundColor: Color(0xFF2C73D9),
                      radius: 24,
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _controller.nextPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                        },
                      ),
                    ),
                    // زر "عودة" يظهر بعد الصفحة الأولى فقط
                    if (_currentIndex > 0)
                      TextButton(
                        onPressed: () {
                          _controller.previousPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.ease,
                          );
                        },
                        child: Text(
                          "عودة",
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xffA2A2A2),
                          ),
                        ),
                      )
                    else
                      SizedBox(width: 50), // للحفاظ على التوازن في التصميم
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// عنصر يمثل كل صفحة من الـ Onboarding
class OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final PageController controller;
  final int pageCount;

  OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.controller,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 64),
          Image.asset(
            image,
            height: MediaQuery.of(context).size.height * 0.25,
            fit: BoxFit.contain,
          ),
          // عرض الصورة الخاصة بكل صفحة
          SizedBox(height: MediaQuery.of(context).size.height * 0.09),
          // المؤشر الدائري الذي يوضح الصفحة الحالية
          SmoothPageIndicator(
            controller: controller,
            count: pageCount,
            effect: ExpandingDotsEffect(
              activeDotColor: const Color(0xFF2C73D9),
              dotHeight: 8,
              dotWidth: 8,
            ),
            textDirection: TextDirection.rtl,
          ),
          SizedBox(height: 24),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          SizedBox(height: 16),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFA2A2A2),
                  wordSpacing: 2,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// كلاس لتصميم الجزء العلوي المنحني من الخلفية
class SemiCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 100);
    path.quadraticBezierTo(
        size.width / 2, size.height - 250, size.width, size.height - 100);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}