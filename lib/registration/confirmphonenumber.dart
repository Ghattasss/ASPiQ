import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myfinalpro/enums.dart';
import 'package:myfinalpro/screens/home_screen.dart'; // Assuming this is your target screen after verification
import 'package:myfinalpro/services/Api_services.dart';

class ConfirmPhoneNumber extends StatefulWidget {
  final String identifier; // Email or Phone number
  final ConfirmationMethod method;
  final String? otpReference; // Potentially used for phone OTP verification
  final String? tempToken; // Temporary JWT for email verification

  const ConfirmPhoneNumber({
    super.key,
    required this.identifier,
    required this.method,
    this.otpReference,
    this.tempToken,
  });

  @override
  State<ConfirmPhoneNumber> createState() => _ConfirmPhoneNumberState();
}

class _ConfirmPhoneNumberState extends State<ConfirmPhoneNumber> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _currentTempToken;

  @override
  void initState() {
    super.initState();
    _currentTempToken = widget.tempToken;
    // طلب التركيز على حقل OTP عند تحميل الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context)
          .requestFocus(FocusNode()); // Request focus generally
    });
  }

  // *** دالة التحقق من OTP المعدلة ***
  Future<void> _verifyOtp() async {
    // --- تعديل: تحديد الطول المتوقع (6 للبريد الإلكتروني) ---
    // لنفترض حاليًا أن الهاتف أيضًا يستخدم 6 أرقام، أو يمكنك تعديلها إذا كان مختلفًا
    int expectedLength = 6;
    // --- نهاية التعديل ---

    if (_otpController.text.isEmpty) {
      setState(() {
        _errorMessage = "الرجاء إدخال رمز التحقق";
      });
      return;
    }
    // --- تعديل: التحقق من الطول الصحيح (6 للبريد الإلكتروني) ---
    if (_otpController.text.length != expectedLength) {
      setState(() {
        _errorMessage = "يجب أن يتكون الرمز من $expectedLength أرقام";
      });
      return;
    }
    // --- نهاية التعديل ---

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;

      if (widget.method == ConfirmationMethod.email) {
        // استدعاء verifyEmailOtp (يفترض أنه يقبل 6 أرقام الآن)
        if (_currentTempToken == null) {
          throw Exception("Temporary token is missing for email verification.");
        }
        print(
            "[_verifyOtp - Email] Calling ApiService.verifyEmailOtp with token and code: ${_otpController.text}");
        result = await ApiService.verifyEmailOtp(
          _currentTempToken,
          _otpController.text,
        );
      } else {
        // Phone verification - تأكد من أن طول الهاتف يتوافق مع expectedLength
        print(
            "[_verifyOtp - Phone] Calling ApiService.verifyOtp with identifier, code: ${_otpController.text}, reference: ${widget.otpReference}");
        result = await ApiService.verifyOtp(
          widget.identifier,
          _otpController.text,
          widget.otpReference,
        );
      }

      print("[_verifyOtp] API Result: $result"); // طباعة نتيجة الـ API

      if (!mounted) return;

      if (result['success']) {
        setState(() {
          _isSuccess = true;
        });
        // التعامل مع التوكن النهائي إذا تم إرجاعه
        if (result['token'] != null) {
          print("Received FINAL Login Token: ${result['token']}");
          // TODO: حفظ التوكن النهائي بشكل آمن
          // await YourSecureStorageService.saveToken(result['token']);
        } else {
          print("Verification successful, but no final login token returned.");
        }

        // الانتقال بعد النجاح
        Future.delayed(Duration(milliseconds: 1200), () {
          if (mounted) {
            print("Navigating to HomeScreen...");
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
                  (Route<dynamic> route) => false,
            );
          }
        });
      } else {
        // فشل الـ API
        setState(() {
          _errorMessage =
              result['message'] ?? "فشل التحقق من الرمز. حاول مرة أخرى.";
          _isSuccess = false;
          print("[_verifyOtp] Verification Failed: $_errorMessage");
        });
      }
    } catch (e) {
      print("[_verifyOtp] Verify OTP Error (${widget.method}): $e");
      if (mounted) {
        setState(() {
          _errorMessage = "حدث خطأ: ${e.toString()}";
          _isSuccess = false;
        });
      }
    } finally {
      // إيقاف التحميل فقط في حالة الفشل (لأن حالة النجاح لها واجهة خاصة)
      if (mounted && !_isSuccess) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // *** نهاية دالة التحقق المعدلة ***

  // *** دالة إعادة إرسال OTP المعدلة (تبقى كما هي منطقيًا) ***
  Future<void> _resendOtp() async {
    print(
        "[_resendOtp] Attempting to resend OTP for ${widget.method} - ${widget.identifier}");
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // --- تعديل: تحديد نوع API (نفترض أن sendOtp يدعم 'email' فقط حاليًا) ---
      // إذا كان لديك API منفصل للهاتف، ستحتاج إلى استدعائه هنا
      String apiType = widget.method == ConfirmationMethod.email
          ? 'email'
          : 'sms'; // 'sms' هو مجرد مثال
      if (apiType != 'email') {
        throw Exception(
            "Resend OTP currently only supported for email via ApiService.sendOtp");
      }
      // --- نهاية التعديل ---

      final result = await ApiService.sendOtp(widget.identifier, apiType);
      print("[_resendOtp] API Result: $result");

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("تم إرسال رمز جديد بنجاح")),
        );
        // تحديث التوكن المؤقت إذا تم إرجاع واحد جديد (مهم للبريد الإلكتروني)
        if (widget.method == ConfirmationMethod.email &&
            result['token'] != null) {
          setState(() {
            _currentTempToken = result['token'];
          });
          print("[_resendOtp] Temporary OTP Token updated after resend.");
        }
      } else {
        // فشل إعادة الإرسال
        setState(() {
          _errorMessage = result['message'] ?? "فشل إعادة إرسال الرمز.";
        });
        print("[_resendOtp] Resend Failed: $_errorMessage");
      }
    } catch (e) {
      print("[_resendOtp] Resend OTP Error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "حدث خطأ: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // *** نهاية دالة إعادة الإرسال المعدلة ***

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    // --- تعديل: استخدام الطول الصحيح (6 للبريد الإلكتروني) ---
    int otpLength = widget.method == ConfirmationMethod.email
        ? 6
        : 6; // استخدام 6 للبريد الإلكتروني (وافترض 6 للهاتف مؤقتًا)
    // --- نهاية التعديل ---
    String hintText = List.generate(otpLength, (_) => '-').join(' ');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Text(
            "تأكيد الحساب",
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
              onPressed: (_isLoading || _isSuccess)
                  ? null
                  : () {
                print("[AppBar] Back button pressed.");
                Navigator.pop(context);
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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: screenHeight * 0.05),
              Center(
                child: Image.asset(
                  "assets/images/Group 1171275992.png",
                  width: screenWidth * 0.8,
                  height: screenHeight * 0.29,
                  fit: BoxFit.contain,
                ),
              ), // تأكد من وجود الصورة
              SizedBox(height: screenHeight * 0.04),
              Text(
                widget.method == ConfirmationMethod.email
                    ? "تم إرسال رمز التحقق إلى بريدك الإلكتروني"
                    : "تم إرسال رمز التحقق إلى رقم هاتفك",
                style: TextStyle(
                  color: Color(0xFF2C73D9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                widget.identifier,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.04),

              // حقل إدخال OTP
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  // السماح بالأرقام فقط
                  // --- تعديل: استخدام الطول الصحيح (6) ---
                  maxLength: otpLength,
                  // --- نهاية التعديل ---
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, letterSpacing: 8),
                  // زيادة التباعد بين الأرقام
                  decoration: InputDecoration(
                    hintText: hintText,
                    counterText: "",
                    // إخفاء عداد الحروف
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                      BorderSide(color: Color(0xFF2C73D9), width: 2),
                    ),
                  ),
                  readOnly: _isSuccess,
                  // منع التعديل بعد النجاح
                  onChanged: (value) {
                    // مسح الخطأ عند البدء في الكتابة
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                ),
              ),

              // رسالة الخطأ
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              SizedBox(height: screenHeight * 0.03),

              // زر التحقق
              ElevatedButton(
                // --- تعديل: استدعاء _verifyOtp عند الضغط ---
                onPressed: (_isLoading || _isSuccess)
                    ? null
                    : () {
                  print("[Button Press] Verify button pressed.");
                  _verifyOtp();
                },
                // --- نهاية التعديل ---
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _isSuccess ? Colors.green : Color(0xFF2C73D9),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: Size(screenWidth * 0.7, 50),
                  disabledBackgroundColor: _isSuccess
                      ? Colors.green.withOpacity(0.7)
                      : Colors.grey.withOpacity(0.5),
                ),
                child: _isLoading && !_isSuccess
                    ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                )
                    : _isSuccess
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text("تم التحقق", style: TextStyle(fontSize: 18)),
                  ],
                )
                    : Text(
                  "تحقق من الرمز",
                  style: TextStyle(fontSize: 18),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // زر إعادة الإرسال
              TextButton(
                // --- تعديل: استدعاء _resendOtp عند الضغط ---
                onPressed: (_isLoading || _isSuccess)
                    ? null
                    : () {
                  print("[Button Press] Resend button pressed.");
                  _resendOtp();
                },
                // --- نهاية التعديل ---
                child: Text(
                  "إعادة إرسال الرمز",
                  style: TextStyle(
                    color: (_isLoading || _isSuccess)
                        ? Colors.grey
                        : Color(0xFF2C73D9),
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}