// lib/login/login_view.dart
import 'package:flutter/material.dart';
import 'package:myfinalpro/login/forgetPassword.dart'; // تأكد من المسار
import 'package:myfinalpro/registration/registration.dart'; // تأكد من المسار
import 'package:shared_preferences/shared_preferences.dart';

// --- استيراد الشاشات اللازمة ---
import '../screens/assessment_screen.dart'; // شاشة التقييم
import '../screens/home_screen.dart';       // شاشة الهوم

import '../services/Api_services.dart'; // خدمة الـ API
import '../widget/custom.dart'; // الويدجت المخصص (CustomTextField)

class LoginView extends StatefulWidget {
  // استخدام const للـ constructor
  const LoginView({super.key});

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _obscureText = true; // لإخفاء/إظهار كلمة المرور
  bool isSelected = false; // لحالة "تذكرني"
  bool isLoading = false; // لعرض مؤشر التحميل
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage; // لعرض رسائل الخطأ

  @override
  void initState() {
    super.initState();
    _loadSavedEmail(); // محاولة تحميل الإيميل المحفوظ عند بدء الشاشة
  }

  @override
  void dispose() {
    // التخلص من الـ controllers لمنع تسرب الذاكرة
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- دوال SharedPreferences ---
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print("LoginView: Token only saved.");
    } catch (e) {
      print("LoginView: Error saving token: $e");
    }
  }

  // دالة لحفظ كل بيانات المستخدم والتوكن والصورة
  Future<void> _saveUserDataAndImage(String token, String name, String email, String? imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await prefs.setString('user_image_url', imageUrl);
        print("LoginView: Image URL saved: $imageUrl");
      } else {
        // إزالة المفتاح إذا كانت القيمة null أو فارغة لضمان عدم وجود قيمة قديمة
        await prefs.remove('user_image_url');
        print("LoginView: Image URL removed or not provided.");
      }
      print("LoginView: User data saved - Name: $name, Email: $email");
    } catch (e) {
      print("LoginView: Error saving user data and image: $e");
    }
  }

  // تحميل الإيميل المحفوظ (إذا وُجد)
  Future<void> _loadSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('saved_email');
      // استخدام mounted للتحقق قبل استدعاء setState
      if (mounted && savedEmail != null) {
        setState(() {
          _emailController.text = savedEmail;
          isSelected = true; // تحديد "تذكرني" تلقائيًا
        });
      }
    } catch (e) {
      print("LoginView: Error loading saved email: $e");
      // لا تحتاج لعرض خطأ للمستخدم هنا عادةً
    }
  }


  // --- دالة تسجيل الدخول المعدلة بالكامل لاستخدام hasCompletedAssessment ---
  Future<void> _login() async {
    // منع الضغط المتعدد أثناء التحميل
    if(isLoading) return;
    // التحقق إذا كانت الواجهة لا تزال موجودة
    if (!mounted) return;

    // بدء التحميل ومسح الأخطاء السابقة
    setState(() { isLoading = true; _errorMessage = null; });

    try {
      // 1. استدعاء API تسجيل الدخول (المعدل)
      final result = await ApiService.loginUser(
          _emailController.text.trim(), // إزالة المسافات الزائدة
          _passwordController.text        // لا تقم بـ trim لكلمة المرور
      );

      // تحقق مرة أخرى قبل التعامل مع النتيجة
      if (!mounted) return;

      // 2. التحقق من نجاح تسجيل الدخول واستلام التوكن
      if (result['success'] == true && result['token'] != null) {
        final String receivedToken = result['token'];

        // --- !!! استلام حالة الاستبيان من النتيجة !!! ---
        final bool hasCompletedAssessment = result['hasCompletedAssessment'] ?? false;
        print("Login Successful. Token received. Has Completed Assessment: $hasCompletedAssessment");

        // 3. (اختياري ولكن موصى به) جلب/تحديث بيانات الملف الشخصي
        // حتى لو أعاد API تسجيل الدخول بعض البيانات، قد ترغب في التأكد من أنها الأحدث
        // أو قد لا يرجع API تسجيل الدخول كل البيانات المطلوبة (مثل الصورة)
        final profileResult = await ApiService.getUserProfile(receivedToken);
        print("--- PROFILE FETCH RESULT ---");
        print("Success: ${profileResult['success']}");
        print("Data: ${profileResult['data']}");
        print("Message: ${profileResult['message']}");
        print("--------------------------");

        // تحقق قبل المتابعة
        if (!mounted) return;

        // قيم افتراضية لبيانات المستخدم
        String fullName = "المستخدم";
        // استخدم الإيميل المدخل كافتراضي إذا فشل جلب الملف الشخصي
        String userEmail = _emailController.text.trim();
        String? imageUrl;

        // 4. استخراج بيانات الملف الشخصي إذا نجح الجلب
        if (profileResult['success'] == true && profileResult['data'] != null && profileResult['data'] is Map) {
          final profileData = profileResult['data'] as Map<String, dynamic>;
          // --- !!! تأكد من أسماء المفاتيح الفعلية هنا من API get-profile !!! ---
          final String firstName = profileData['name'] ?? profileData['Name'] ?? '';
          final String lastName = profileData['surname'] ?? profileData['Surname'] ?? '';
          userEmail = profileData['email'] ?? profileData['Email'] ?? userEmail; // استخدم الإيميل من الملف الشخصي إن وجد
          imageUrl = profileData['image_url']?.toString() ?? profileData['Image_']?.toString() ?? profileData['profilePicture']?.toString();
          // ----------------------------------------------------
          fullName = '$firstName $lastName'.trim(); // دمج الاسم الأول والأخير
          if (fullName.isEmpty) fullName = "مستخدم جديد"; // اسم افتراضي إذا كانت الأسماء فارغة
        } else {
          // فشل جلب الملف الشخصي (بعد تسجيل دخول ناجح)
          print("Warning: Login successful, but failed to fetch/parse profile details: ${profileResult['message']}");
          // سنستخدم القيم الافتراضية المحفوظة أعلاه (الإيميل المدخل واسم "المستخدم")
          // ما زال يجب حفظ التوكن
          await _saveToken(receivedToken); // احفظ التوكن فقط
          // يمكنك عرض رسالة تحذير إذا أردت، لكن استمر في التنقل
          // setState(() { _errorMessage = 'تم الدخول، لكن فشل تحميل بيانات الملف الشخصي.'; });
        }

        // 5. حفظ كل البيانات (التوكن، الاسم، الإيميل، الصورة) إذا نجح جلب الملف الشخصي
        if (profileResult['success'] == true) {
          print("==> Attempting to save user data and image...");
          await _saveUserDataAndImage(receivedToken, fullName, userEmail, imageUrl);
          print("==> User data and image save function called.");
        } // إذا فشل جلب الملف، تم حفظ التوكن فقط أعلاه

        // 6. حفظ الإيميل إذا تم تحديد "تذكرني"
        if (isSelected) {
          try {
            final prefs = await SharedPreferences.getInstance();
            // التحقق قبل الحفظ
            if (mounted) {
              await prefs.setString('saved_email', _emailController.text.trim());
              print("LoginView: Email saved for 'Remember Me'.");
            }
          } catch (e) {
            print("LoginView: Error saving email for 'Remember Me': $e");
          }
        } else {
          // إذا لم يتم تحديد "تذكرني"، قم بإزالة الإيميل المحفوظ سابقًا (إن وجد)
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('saved_email');
            print("LoginView: Saved email removed (Remember Me unchecked).");
          } catch (e) {
            print("LoginView: Error removing saved email: $e");
          }
        }


        // 7. --- !!! التنقل المشروط بناءً على حالة الاستبيان !!! ---
        if (!mounted) return; // تحقق أخير قبل التنقل

        if (hasCompletedAssessment) {
          print("Navigating to HomeScreen (Assessment Complete)...");
          // الانتقال إلى الشاشة الرئيسية مع إزالة كل الشاشات السابقة من المكدس
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (Route<dynamic> route) => false, // دالة الإزالة
          );
        } else {
          print("Navigating to AssessmentScreen (Assessment Pending)...");
          // الانتقال إلى شاشة الاستبيان مع تمرير التوكن وإزالة الشاشات السابقة
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => AssessmentScreen(jwtToken: receivedToken)),
                (Route<dynamic> route) => false, // دالة الإزالة
          );
        }
        // ----------------------------------------------------------

      } else {
        // فشل تسجيل الدخول (من API)
        if (mounted) {
          setState(() {
            // استخدم رسالة الخطأ من الـ API مباشرة
            _errorMessage = result['message'] ?? 'فشل تسجيل الدخول. تأكد من البريد وكلمة المرور.';
          });
        }
      }
    } catch (e, s) {
      // التعامل مع الأخطاء العامة (مثل أخطاء الشبكة قبل استدعاء API أو أخطاء غير متوقعة)
      print("Login View - General Error Catch: $e");
      print("Login View - Stacktrace: $s");
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع. تحقق من اتصالك بالإنترنت أو حاول مرة أخرى.';
        });
      }
    } finally {
      // إيقاف مؤشر التحميل دائمًا في النهاية
      if (mounted) {
        setState(() { isLoading = false; });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // استخدام Directionality هنا إذا لم تكن قد قمت بذلك في main.dart
    return Directionality(
      textDirection: TextDirection.rtl, // ضمان الاتجاه من اليمين لليسار
      child: Scaffold(
        backgroundColor:Colors.white,
        body: SingleChildScrollView( // للسماح بالتمرير على الشاشات الصغيرة
          child: Padding( // إضافة Padding حول المحتوى
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.1), // مسافة من الأعلى
                // --- الشعار ---
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Image.asset(
                    "assets/images/logo.png", // تأكد من مسار الشعار
                    width: screenWidth * 0.5,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 80), // بديل في حالة الخطأ
                  ),
                ),
                const SizedBox(height: 15), // تقليل المسافة قليلاً
                // --- عنوان تسجيل الدخول ---
                const Text(
                  "تسجيل الدخول",
                  style: TextStyle(
                    color: Color(0xFF2C73D9), // لون أزرق مميز
                    fontSize: 24, // حجم أكبر للعنوان
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30), // مسافة قبل حقول الإدخال

                // --- حقل البريد الإلكتروني ---
                CustomTextField(
                  hintText: "أدخل البريد الإلكتروني",
                  obscureText: false,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress, // لوحة مفاتيح مناسبة للإيميل
                  validator: (value) { // إضافة تحقق بسيط (اختياري)
                    if (value == null || value.trim().isEmpty) {
                      return 'البريد الإلكتروني مطلوب';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'صيغة البريد الإلكتروني غير صحيحة';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15), // مسافة بين الحقول

                // --- حقل كلمة المرور ---
                CustomTextField(
                  hintText: "أدخل كلمة المرور",
                  obscureText: _obscureText, // للتحكم في الإخفاء
                  controller: _passwordController,
                  // تمرير بيانات أيقونة تبديل الرؤية
                  suffixIcon: _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  // تمرير الدالة التي سيتم استدعاؤها عند الضغط على الأيقونة
                  onSuffixIconPressed: () {
                    // تحديث حالة الواجهة لتبديل الرؤية
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  validator: (value) { // إضافة تحقق بسيط (اختياري)
                    if (value == null || value.isEmpty) {
                      return 'كلمة المرور مطلوبة';
                    }
                    // يمكنك إضافة تحقق على الطول إذا أردت
                    // if (value.length < 6) {
                    //   return 'كلمة المرور قصيرة جدًا';
                    // }
                    return null;
                  },
                ),

                // --- عرض رسالة الخطأ ---
                // استخدام Visibility للتحكم في ظهور/إخفاء عنصر الخطأ
                Visibility(
                  visible: _errorMessage != null, // يظهر فقط إذا كان هناك خطأ
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 5), // مسافات حول النص
                    child: Text(
                      _errorMessage ?? '', // استخدام القيمة أو نص فارغ
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 10), // مسافة قبل خيارات "تذكرني"

                // --- صف تذكرني ونسيت كلمة المرور ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // توزيع المسافة
                  children: [
                    // --- جزء "تذكرني" ---
                    InkWell( // لجعل النص قابلاً للنقر أيضًا
                      onTap: () => setState(() { isSelected = !isSelected; }),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // لحجم مناسب
                        children: [
                          SizedBox( // للتحكم في حجم Checkbox لتسهيل النقر
                            width: 24, height: 24,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() { isSelected = value ?? false; });
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // تقليل مساحة النقر الافتراضية
                              visualDensity: VisualDensity.compact, // مظهر مضغوط
                              activeColor: const Color(0xFF2C73D9), // لون التحديد
                            ),
                          ),
                          // const SizedBox(width: 4), // مسافة صغيرة جدًا
                          const Text(
                            "تذكرني",
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    // --- رابط "نسيت كلمة المرور" ---
                    InkWell(
                      onTap: () {
                        if (!isLoading) { // منع النقر أثناء التحميل
                          Navigator.push( context, MaterialPageRoute( builder: (context) => const ForgetPassword()),); // تأكد من اسم الكلاس الصحيح
                        }
                      },
                      child: const Text(
                        "هل نسيت كلمة المرور؟",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2C73D9), // لون مميز للرابط
                          // decoration: TextDecoration.underline, // اختياري: إضافة خط سفلي
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25), // مسافة قبل زر الدخول

                // --- زر تسجيل الدخول ---
                ElevatedButton(
                  // تعطيل الزر أثناء التحميل
                  onPressed: isLoading ? null : _login, // <-- استدعاء دالة تسجيل الدخول المعدلة
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C73D9), // لون الزر الأساسي
                    foregroundColor: Colors.white, // لون النص والأيقونة داخل الزر
                    minimumSize: const Size(double.infinity, 50), // عرض كامل وارتفاع مناسب
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // حواف دائرية
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12), // مسافات داخلية للزر
                    elevation: 3, // ظل خفيف
                    disabledBackgroundColor: Colors.grey.shade400, // لون الزر عند التعطيل
                  ),
                  child: isLoading
                  // عرض مؤشر تحميل دائري أثناء التحميل
                      ? const SizedBox(
                    height: 24, // حجم مناسب للمؤشر
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white, // لون المؤشر
                      strokeWidth: 3, // سمك الخط
                    ),
                  )
                  // عرض نص الزر في الحالة العادية
                      : const Text(
                    "تسجيل الدخول",
                    style: TextStyle(
                      // لون النص محدد في foregroundColor
                      fontSize: 18, // حجم خط مناسب
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20), // مسافة قبل رابط إنشاء حساب

                // --- رابط إنشاء حساب جديد ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center, // توسيط العناصر
                  children: [
                    const Text(
                      "لا تمتلك حساب؟",
                      style: TextStyle(
                        color: Color(0xFF4A4A4A), // لون رمادي داكن
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 5), // مسافة صغيرة
                    InkWell(
                      onTap: () {
                        if (!isLoading) { // منع النقر أثناء التحميل
                          Navigator.push( context, MaterialPageRoute( builder: (context) => const RegistrationView()),); // تأكد من اسم الكلاس الصحيح
                        }
                      },
                      child: const Text(
                        "أنشئ حساب جديد",
                        style: TextStyle(
                          color: Color(0xFF2C73D9), // لون مميز للرابط
                          fontSize: 15,
                          fontWeight: FontWeight.bold, // خط عريض
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40), // مسافة سفلية إضافية
              ],
            ),
          ),
        ),
      ),
    );
  }
}