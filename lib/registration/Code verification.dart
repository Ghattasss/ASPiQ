import 'dart:math'; // لاستخدام min لحساب حجم المربع

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لاستخدام InputFormatter

// --- تأكد من اسم الملف الصحيح لشاشة كلمة المرور الجديدة ---
// import '../login/New_password.dart'; // هل هذا هو الاسم الصحيح؟ كان اسمه new_password_screen.dart
import '../login/New_password.dart'; // <<-- استخدام الاسم القياسي الذي أنشأناه
// --- نهاية التأكد ---
import '../login/login_view.dart'; // استيراد شاشة تسجيل الدخول للرجوع
import '../services/Api_services.dart'; // استيراد ApiService

class CodeVerification extends StatefulWidget {
  final String email;
  final String token; // هذا هو الـ token المؤقت من Send-OTP

  const CodeVerification({
    Key? key,
    required this.email,
    required this.token,
  }) : super(key: key);

  @override
  State<CodeVerification> createState() => _CodeVerificationState();
}

class _CodeVerificationState extends State<CodeVerification> {
  // --- تعديل: تغيير العدد إلى 6 ---
  static const int otpLength = 6;
  final List<TextEditingController> _controllers =
  List.generate(otpLength, (index) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(otpLength, (index) => FocusNode());

  // --- نهاية التعديل ---

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otpCode {
    return _controllers.map((controller) => controller.text).join();
  }

  // التحقق من الرمز باستخدام ApiService
  Future<void> _verifyOtpCode() async {
    // --- طباعة عند الدخول للدالة ---
    print("--- دخلت دالة _verifyOtpCode ---");
    final currentOtp = _otpCode;
    // --- طباعة القيم قبل التحقق ---
    print(
        "[_verifyOtpCode] الرمز للتحقق: '$currentOtp' (الطول: ${currentOtp.length})");
    // اطبع جزءًا من التوكن إذا كان طويلاً لتجنب إغراق السجل
    String tokenPart = widget.token.length > 20
        ? '${widget.token.substring(0, 10)}...${widget.token.substring(widget.token.length - 10)}'
        : widget.token;
    print("[_verifyOtpCode] التوكن المستخدم (جزئي): '$tokenPart'");

    // --- تعديل: التحقق من طول الرمز (6) ---
    if (currentOtp.length != otpLength) {
      // --- طباعة سبب الخروج ---
      print("[_verifyOtpCode] !! الخروج المبكر: طول الرمز ليس $otpLength");
      _clearOtpFields();
      setState(() {
        _errorMessage = 'يرجى إدخال رمز التحقق المكون من $otpLength أرقام';
      });
      FocusScope.of(context).requestFocus(_focusNodes[0]);
      return;
    }
    // --- نهاية التعديل ---

    // إلغاء تركيز آخر حقل
    _focusNodes[otpLength - 1].unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // --- طباعة قبل استدعاء API ---
      print(
          "[_verifyOtpCode] >>> استدعاء ApiService.verifyEmailOtp بالرمز: $currentOtp");
      final result = await ApiService.verifyEmailOtp(widget.token, currentOtp);
      // --- طباعة النتيجة ---
      print("[_verifyOtpCode] <<< نتيجة ApiService.verifyEmailOtp: $result");

      if (!mounted) {
        print("[_verifyOtpCode] !! الويدجت لم يعد mounted بعد استدعاء API.");
        return;
      }

      if (result['success']) {
        print(
            "[_verifyOtpCode] >> نجاح التحقق من API. الانتقال إلى NewPasswordScreen.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ??
                  'تم التحقق بنجاح. الرجاء إدخال كلمة المرور الجديدة.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // تأكد من استخدام الاسم الصحيح لملف الشاشة الجديدة
            builder: (context) => NewPasswordScreen(token: widget.token),
          ),
        );
      } else {
        // --- طباعة رسالة الفشل ---
        print("[_verifyOtpCode] !! فشل التحقق من API: ${result['message']}");
        _clearOtpFields();
        FocusScope.of(context).requestFocus(_focusNodes[0]);
        setState(() {
          // تعديل رسالة الخطأ لتعكس 6 أرقام إذا لزم الأمر
          if (result['message']?.contains('4 أرقام') ?? false) {
            _errorMessage = (result['message'] ?? '')
                .replaceAll('4 أرقام', '$otpLength أرقام');
          } else {
            _errorMessage =
                result['message'] ?? 'فشل التحقق من الرمز. حاول مرة أخرى.';
          }
        });
      }
    } catch (e) {
      // --- طباعة الخطأ ---
      print("[_verifyOtpCode] !! خطأ Catch في _verifyOtpCode: $e");
      if (!mounted) return;
      _clearOtpFields();
      FocusScope.of(context).requestFocus(_focusNodes[0]);
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التحقق: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // دالة لمسح حقول OTP
  void _clearOtpFields() {
    print("[_clearOtpFields] مسح حقول OTP.");
    for (var controller in _controllers) {
      controller.clear();
    }
  }

  // إعادة إرسال الرمز (تبقى كما هي)
  Future<void> _resendOtp() async {
    print("[_resendOtp] --- طلب إعادة إرسال الرمز ---");
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      print(
          "[_resendOtp] >>> استدعاء ApiService.sendOtp للإيميل: ${widget.email}");
      final resendResult = await ApiService.sendOtp(widget.email, 'email');
      print("[_resendOtp] <<< نتيجة ApiService.sendOtp: $resendResult");

      if (!mounted) {
        print("[_resendOtp] !! الويدجت لم يعد mounted بعد إعادة الإرسال.");
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(resendResult['message'] ??
                (resendResult['success']
                    ? 'تم إعادة إرسال الرمز.'
                    : 'فشل إعادة الإرسال.'))),
      );
      if (resendResult['success']) {
        _clearOtpFields();
        FocusScope.of(context).requestFocus(_focusNodes[0]);
        // ملاحظة: إذا أعاد Send-OTP توكن جديدًا، يجب تحديثه هنا إذا لزم الأمر
        // if (resendResult['token'] != null && resendResult['token'] != widget.token) {
        //   print("[_resendOtp] تنبيه: تم استلام توكن جديد عند إعادة الإرسال.");
        //   // تحديث التوكن هنا يتطلب تغييرات إضافية (مثل استخدام StatefulWidget أو state management)
        // }
      } else if (!resendResult['success']) {
        setState(() {
          _errorMessage = resendResult['message'] ?? 'فشل إعادة إرسال الرمز.';
          print("[_resendOtp] !! فشل إعادة الإرسال: $_errorMessage");
        });
      }
    } catch (e) {
      print("[_resendOtp] !! خطأ Catch في _resendOtp: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = 'خطأ في الشبكة أثناء إعادة الإرسال.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // --- حساب حجم المربع والمسافات لـ 6 حقول ---
    int numberOfSpaces = otpLength + 1;
    double totalHorizontalPadding = screenWidth * 0.08;
    double spaceBetweenBoxes = 8;
    double totalSpacing = spaceBetweenBoxes * (otpLength - 1);
    double availableWidth = screenWidth - totalHorizontalPadding - totalSpacing;
    double boxSize = availableWidth / otpLength;
    boxSize = min(boxSize, 55.0);
    boxSize = max(boxSize, 40.0);
    // --- نهاية التعديل ---

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Text(
            "التحقق من الرمز ",
            style: TextStyle(
              color: Color(0xFF2C73D9),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, right: 8.0),
            child: IconButton(
              onPressed: () {
                print("[AppBar] الضغط على زر الرجوع -> الانتقال إلى LoginView");
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginView()),
                      (Route<dynamic> route) => false,
                );
              },
              icon: Icon(
                Icons.keyboard_arrow_right_outlined,
                size: 40,
                color: Color(0xFF2C73D9),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: totalHorizontalPadding / 2),
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              Center(
                child: Image.asset(
                  "assets/images/pana.png",
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.29,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                "تم إرسال رمز إلى بريدك الإلكتروني:",
                style: TextStyle(
                  color: Color(0xFF2C73D9),
                  fontSize: 17,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.email,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                "الرجاء إدخال رمز التحقق المكون من $otpLength أرقام",
                style: TextStyle(
                  color: Color(0xFF2C73D9),
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.03),

              // حقول إدخال الـ OTP
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(otpLength, (index) {
                    return Container(
                      width: boxSize,
                      height: boxSize + 5,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          counterText: "",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                            BorderSide(color: Color(0xFF2C73D9), width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: max(5, (boxSize - 20) / 2)),
                        ),
                        onChanged: (value) {
                          // --- طباعة عند تغيير القيمة ---
                          // print("onChanged - الحقل $index: '$value'");
                          setState(() {
                            _errorMessage = null;
                          });
                          if (value.isNotEmpty) {
                            if (index < otpLength - 1) {
                              // print("onChanged - نقل التركيز من $index إلى ${index + 1}");
                              _focusNodes[index].unfocus();
                              FocusScope.of(context)
                                  .requestFocus(_focusNodes[index + 1]);
                            } else {
                              // --- طباعة عند ملء الحقل الأخير ---
                              print(
                                  "[onChanged] الحقل الأخير ($index) تم ملؤه. الرمز الحالي: '${_otpCode}' (الطول: ${_otpCode.length})");
                              _focusNodes[index].unfocus();
                              if (_otpCode.length == otpLength) {
                                print("[onChanged] محاولة التحقق التلقائي...");
                                _verifyOtpCode();
                              }
                            }
                          } else {
                            // الرجوع عند الحذف
                            if (index > 0) {
                              // print("onChanged - نقل التركيز للخلف من $index إلى ${index - 1}");
                              _focusNodes[index].unfocus();
                              FocusScope.of(context)
                                  .requestFocus(_focusNodes[index - 1]);
                            }
                          }
                        },
                      ),
                    );
                  }),
                ),
              ),

              // عرض رسالة الخطأ
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(height: screenHeight * 0.05),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ElevatedButton(
                  // --- طباعة عند الضغط على الزر ---
                  onPressed: _isLoading || _isResending
                      ? null
                      : () {
                    print("[Button Press] الضغط على زر التحقق.");
                    _verifyOtpCode();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C73D9),
                    minimumSize: Size(screenWidth, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Center(
                    child: _isLoading
                        ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ))
                        : const Text(
                      "تحقق",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),

              // زر إعادة الإرسال
              TextButton(
                // --- طباعة عند الضغط على الزر ---
                onPressed: _isLoading || _isResending
                    ? null
                    : () {
                  print("[Button Press] الضغط على زر إعادة الإرسال.");
                  _resendOtp();
                },
                child: _isResending
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF2C73D9),
                        )),
                    SizedBox(width: 8),
                    Text("جاري إعادة الإرسال...",
                        style: TextStyle(color: Colors.grey)),
                  ],
                )
                    : Text(
                  "لم تستلم الرمز؟ إعادة الإرسال",
                  style: TextStyle(color: Color(0xFF2C73D9)),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}