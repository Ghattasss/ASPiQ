import 'package:flutter/material.dart';

class About_App extends StatefulWidget {
  const About_App({super.key});

  @override
  State<About_App> createState() => _About_AppState();
}

class _About_AppState extends State<About_App> {
  // استخدام متغيرات منفصلة لكل قسم لتتبع حالة التوسيع
  bool isWhatExpanded = false;
  bool isTargetExpanded = false;
  bool isLevelsExpanded = false;
  bool isHowItWorksExpanded = false;

  // دالة مساعدة لإنشاء حاوية المحتوى (لتجنب تكرار الكود)
  Widget _buildContentContainer(BuildContext context, String text) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      // هامش أفقي قليل لجعل الصندوق أضيق قليلاً من عرض الشاشة
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100], // لون خلفية خفيف للتمييز
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C73D9).withOpacity(0.5), width: 1), // إطار أفتح قليلاً
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16, // حجم خط المحتوى
          color: Color(0XFF2C73D9),
          height: 1.5, // تباعد الأسطر لتحسين القراءة
        ),
        textAlign: TextAlign.right, // محاذاة النص لليمين
      ),
    );
  }

  // دالة مساعدة لإنشاء صف العنوان القابل للنقر (لتجنب تكرار الكود)
  Widget _buildHeaderRow({
    required BuildContext context,
    required String title,
    required bool isExpanded,
    required VoidCallback onTap, // دالة تُستدعى عند النقر
  }) {
    return InkWell(
      onTap: onTap, // استدعاء الدالة الممررة
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding( // إضافة Padding حول الصف لزيادة مساحة النقر
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(
                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFF2C73D9),
                size: 30,
              ),
              const SizedBox(width: 15), // تقليل المسافة قليلاً
              // استخدام Expanded لضمان أن النص يأخذ المساحة المتاحة ولا يسبب overflow
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF2C73D9),
                    fontSize: 20, // حجم خط العنوان
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis, // لإضافة ... إذا كان النص طويلاً جداً
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // يخفي زر الرجوع الافتراضي
        elevation: 1, // ظل خفيف تحت الـ AppBar
        shadowColor: Colors.grey.shade200,
        backgroundColor: Colors.white, // لون خلفية الـ AppBar
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 0), // تعديل الـ Padding إذا لزم الأمر
          child: Text(
            "حول التطبيق", // إزالة المسافة الزائدة
            style: TextStyle(
              color: Color(0xFF2C73D9),
              fontSize: 22, // حجم أصغر قليلاً للعنوان الرئيسي
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            // تعديل الـ Padding ليتناسب مع الـ AppBar
            padding: const EdgeInsets.only(top: 0, right: 8.0, bottom: 0),
            child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded, // أيقونة أنسب للرجوع في iOS/Material
                  size: 28, // حجم أصغر للأيقونة
                  color: Color(0xFF2C73D9),
                )),
          ),
        ],
      ),
      // استخدام SingleChildScrollView للسماح بالتمرير إذا أصبح المحتوى طويلاً
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, // زيادة الـ Padding الأفقي قليلاً
            vertical: screenHeight * 0.03, // تقليل الـ Padding العمودي قليلاً
          ),
          // استخدام ListView.separated لبناء العناصر مع فواصل تلقائية
          child: ListView.separated(
            shrinkWrap: true, // لمنع ListView من أخذ ارتفاع لا نهائي
            physics: const NeverScrollableScrollPhysics(), // لمنع التمرير داخل ListView نفسها (التمرير يتم بواسطة SingleChildScrollView)
            itemCount: 4, // عدد الأقسام
            separatorBuilder: (context, index) => SizedBox(height: screenHeight * 0.015), // فاصل بين الأقسام
            itemBuilder: (context, index) {
              // بناء كل قسم بناءً على الـ index
              if (index == 0) {
                // --- القسم الأول: ما هو AspIQ ؟ ---
                return Column(
                  children: [
                    _buildHeaderRow(
                      context: context,
                      title: "ما هو AspIQ ؟",
                      isExpanded: isWhatExpanded,
                      onTap: () => setState(() => isWhatExpanded = !isWhatExpanded),
                    ),
                    // استخدام AnimatedCrossFade لتأثير ظهور/إخفاء أنعم
                    AnimatedCrossFade(
                      firstChild: Container(), // عنصر فارغ عندما يكون مخفيًا
                      secondChild: Padding( // إضافة Padding فوق المحتوى
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildContentContainer(context,
                          "تطبيق AspIQ يهدف إلى دعم الأطفال المصابين بمتلازمة أسبرجر وأقرانهم في تطوير مهارات الذكاء الوجداني والاجتماعي. من خلال التدريب الموجه والأنشطة التفاعلية، يساعد التطبيق الأطفال على فهم مشاعرهم والتحكم فيها، وكذلك فهم مشاعر الآخرين والتفاعل معها بشكل إيجابي. يركز التطبيق أيضًا على تنمية المهارات الاجتماعية والعاطفية التي تساهم في تعزيز قدرة الطفل على التفاعل بشكل إيجابي في مختلف المواقف الاجتماعية، وتحسين مهارات التواصل والتعاون وحل المشكلات. يمكن للأطفال تعلم كيفية بناء علاقات اجتماعية صحية، إدارة الانفعالات بشكل مناسب، والتفاعل مع الآخرين بطرق تساعدهم على التكيف بنجاح في بيئاتهم الاجتماعية.",
                        ),
                      ),
                      crossFadeState: isWhatExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300), // مدة التأثير
                    ),
                  ],
                );
              } else if (index == 1) {
                // --- القسم الثاني: الفئة المستهدفة ---
                return Column(
                  children: [
                    _buildHeaderRow(
                      context: context,
                      title: "الفئة المستهدفة",
                      isExpanded: isTargetExpanded,
                      onTap: () => setState(() => isTargetExpanded = !isTargetExpanded),
                    ),
                    AnimatedCrossFade(
                      firstChild: Container(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildContentContainer(context,
                          "تم تصميم تطبيق AspIQ بشكل أساسي للأطفال الذين تتراوح أعمارهم بين 6 و 12 عامًا، خاصةً أولئك الذين تم تشخيصهم بمتلازمة أسبرجر أو يظهرون تحديات في التفاعل الاجتماعي والذكاء الوجداني. كما يمكن أن يستفيد منه أقرانهم لتنمية فهم أعمق لاختلافات الآخرين وتعزيز مهاراتهم الاجتماعية.",
                        ),
                      ),
                      crossFadeState: isTargetExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                );
              } else if (index == 2) {
                // --- القسم الثالث: المستويات ---
                return Column(
                  children: [
                    _buildHeaderRow(
                      context: context,
                      title: "المستويات والمحتوى",
                      isExpanded: isLevelsExpanded,
                      onTap: () => setState(() => isLevelsExpanded = !isLevelsExpanded),
                    ),
                    AnimatedCrossFade(
                      firstChild: Container(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildContentContainer(context,
                          "يقدم التطبيق محتوى متنوعًا يركز على قسمين رئيسيين:\n\n" // استخدام \n لسطر جديد
                          "1.  **فهم وإدارة الانفعالات:** يتعلم الطفل التعرف على مشاعر مختلفة مثل الفرح، الحزن، الغضب، الخوف، الخجل، والمفاجأة، وكيفية التعبير عنها وإدارتها بطرق مناسبة. يتضمن أنشطة تساعد الطفل على التفكير في المواقف المختلفة وردود الفعل العاطفية.\n\n"
                          "2.  **تنمية المهارات الاجتماعية:** يشمل أنشطة لتعزيز مهارات التواصل (اللفظي وغير اللفظي)، التعاون مع الآخرين، فهم وجهات نظر مختلفة، والمبادرة في المواقف الاجتماعية وحل المشكلات البسيطة.",
                        ),
                      ),
                      crossFadeState: isLevelsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                );
              } else {
                // --- القسم الرابع: كيف يعمل AspIQ ؟ ---
                return Column(
                  children: [
                    _buildHeaderRow(
                      context: context,
                      title: "كيف يعمل AspIQ ؟",
                      isExpanded: isHowItWorksExpanded,
                      onTap: () => setState(() => isHowItWorksExpanded = !isHowItWorksExpanded),
                    ),
                    AnimatedCrossFade(
                      firstChild: Container(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildContentContainer(context,
                          "يعمل التطبيق عن طريق تقديم خطط تدريبية وأنشطة تفاعلية مصممة خصيصًا لتلبية احتياجات الطفل. تبدأ هذه الخطط بتقييم مبدئي لتحديد نقاط القوة والتحديات لدى الطفل، ثم تقدم أنشطة متنوعة (قصص، ألعاب، سيناريوهات) بشكل تدريجي ومناسب لعمره ومستواه. يتيح التطبيق تتبع تقدم الطفل وتقديم ملاحظات لمساعدته على التطور المستمر.",
                        ),
                      ),
                      crossFadeState: isHowItWorksExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}