import 'package:flutter/material.dart';
import 'package:myfinalpro/enums.dart';
import 'package:myfinalpro/registration/confirmphonenumber.dart';
import 'package:myfinalpro/services/Api_services.dart';

class AccountConformation extends StatefulWidget {
  final String email;
  final String? phone;

  const AccountConformation({
    super.key,
    required this.email,
    this.phone,
  });

  @override
  State<AccountConformation> createState() => _AccountConformationState();
}

class _AccountConformationState extends State<AccountConformation> {
  ConfirmationMethod? _selectedMethod;
  bool _isLoading = false;
  String? _errorMessage;

  // *** MODIFIED Function to call Send OTP and handle the temporary token ***
  Future<void> _sendOtp(ConfirmationMethod method) async {
    if (_isLoading) return; // Prevent multiple calls

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _selectedMethod = method; // Visually select the method immediately
    });

    String? identifier;
    String? apiMethodType; // Still useful for differentiating logic if needed

    if (method == ConfirmationMethod.email) {
      identifier = widget.email;
      apiMethodType = 'email'; // Type 'email' is now mainly for internal logic
    } else if (method == ConfirmationMethod.phone) {
      identifier = widget.phone;
      apiMethodType = 'sms'; // Assuming 'sms' for phone type
      // <<<--- IMPORTANT: If phone OTP uses a *different* ApiService call or needs 'identifier'/'type', adjust ApiService.sendOtp or add a new method ---<<<
      // The current ApiService.sendOtp is tailored for the EMAIL endpoint (/Send-OTP with 'email' payload)
      // If phone OTP uses '/send-otp' with 'identifier'/'type' payload, you'll need to adjust ApiService.sendOtp
      // or create a separate ApiService.sendPhoneOtp method.
      // For now, we assume the phone path might fail or needs adjustment in ApiService if it uses the same `sendOtp` function.
    }

    // Validate identifier
    if (identifier == null || identifier.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = method == ConfirmationMethod.phone
            ? "رقم الهاتف غير متوفر"
            : "البريد الإلكتروني غير متوفر";
        // Deselect method visually on validation failure
        _selectedMethod = null;
      });
      return;
    }

    try {
      // Call our ApiService to send the OTP
      // NOTE: Assumes ApiService.sendOtp now handles the specific logic for email
      // and potentially needs adjustment/separation for phone.
      final result = await ApiService.sendOtp(
          identifier, apiMethodType!); // Pass type for potential internal logic

      if (result['success']) {
        // <<<--- Extract the temporary token (for email) ---<<<
        String? tempOtpToken;
        if (method == ConfirmationMethod.email) {
          tempOtpToken = result['token']; // Get token from sendOtp result
          if (tempOtpToken == null || tempOtpToken.isEmpty) {
            // Handle case where backend didn't return token even on success (shouldn't happen if fixed)
            throw Exception(
                'Token was not returned by the API upon successful OTP send.');
          }
          print("Temporary OTP Token received: $tempOtpToken"); // For debugging
        }
        // For phone, we might still use otpReference if that API provides it differently
        String? otpReference = result['data']?['reference'];

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmPhoneNumber(
                identifier: identifier!,
                method: method,
                // <<<--- Pass the temporary token OR otpReference ---<<<
                otpReference: otpReference, // Keep for phone or if needed
                tempToken:
                tempOtpToken, // Pass the temporary JWT token for email verification
              ),
            ),
          );
        }
      } else {
        // API Error (Could be 500 from backend, validation error like User not found, etc.)
        setState(() {
          _errorMessage =
              result['message'] ?? 'فشل إرسال الرمز. حاول مرة أخرى.';
          // Deselect method visually on API failure
          _selectedMethod = null;
        });
      }
    } catch (e) {
      print("Send OTP Error in AccountConformation: $e"); // Debug
      setState(() {
        // Display a user-friendly network error or the specific error message
        _errorMessage =
        "حدث خطأ: ${e.toString()}"; // Show the actual exception message
        // Deselect method visually on exception
        _selectedMethod = null;
      });
    } finally {
      // Ensure loading indicator stops ONLY if the widget is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Keep _selectedMethod as is if successful (user sees the checkmark)
          // It's reset to null inside error/catch blocks if needed.
        });
      }
    }
  }

  // *** END OF MODIFIED FUNCTION ***

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    bool canUsePhone = widget.phone != null && widget.phone!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
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
                onPressed: _isLoading
                    ? null
                    : () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.keyboard_arrow_right_outlined,
                  size: 40,
                  color: Color(0xFF2C73D9),
                )),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.05),
            Center(
              child: Image.asset(
                "assets/images/Group 1171275992.png",
                // Ensure this asset exists
                width: screenWidth * 0.8,
                height: screenHeight * 0.29,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(
              height: screenHeight * 0.07,
            ),
            Text(
              "كيف تفضل تأكيد الحساب؟",
              style: TextStyle(
                color: Color(0xFF2C73D9),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: screenHeight * 0.02,
            ),

            // --- Email Option ---
            InkWell(
              onTap: () => _sendOtp(ConfirmationMethod.email),
              child: Opacity(
                opacity:
                _isLoading && _selectedMethod != ConfirmationMethod.email
                    ? 0.5
                    : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Selection Circle
                      Container(
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedMethod == ConfirmationMethod.email
                              ? Colors.blue
                              : Colors.transparent,
                          border: Border.all(
                              color: _selectedMethod == ConfirmationMethod.email
                                  ? Colors.blue
                                  : Color(0xFF2C73D9),
                              width: 2),
                        ),
                        child: _selectedMethod == ConfirmationMethod.email
                            ? Icon(Icons.check, size: 15, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "عبر البريد الإلكتروني",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.002),
                            Text(
                              widget.email, // Display actual email
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      // Icon
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: screenWidth * 0.12,
                            height: screenWidth * 0.12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF2C73D9),
                            ),
                          ),
                          if (_isLoading &&
                              _selectedMethod == ConfirmationMethod.email)
                            SizedBox(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          else
                            Icon(
                              Icons.alternate_email,
                              color: Colors.white,
                              size: screenWidth * 0.06,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(
              height: screenHeight * 0.02,
            ),

            // --- Phone Option ---
            InkWell(
              onTap: (!canUsePhone ||
                  (_isLoading &&
                      _selectedMethod != ConfirmationMethod.phone))
                  ? null
                  : () => _sendOtp(ConfirmationMethod.phone),
              child: Opacity(
                opacity: !canUsePhone ||
                    (_isLoading &&
                        _selectedMethod != ConfirmationMethod.phone)
                    ? 0.5
                    : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Selection Circle
                      Container(
                        width: screenWidth * 0.06,
                        height: screenWidth * 0.06,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedMethod == ConfirmationMethod.phone
                              ? Colors.blue
                              : Colors.transparent,
                          border: Border.all(
                              color: !canUsePhone
                                  ? Colors.grey // Disabled color
                                  : (_selectedMethod == ConfirmationMethod.phone
                                  ? Colors.blue
                                  : Color(0xFF2C73D9)),
                              width: 2),
                        ),
                        child: _selectedMethod == ConfirmationMethod.phone
                            ? Icon(Icons.check, size: 15, color: Colors.white)
                            : null,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      // Text Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              " عبر رقم الهاتف",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                                color:
                                !canUsePhone ? Colors.grey : Colors.black,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.002),
                            Text(
                              canUsePhone
                                  ? widget.phone!
                                  : "رقم الهاتف غير متاح",
                              // Display actual phone or message
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      // Icon
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: screenWidth * 0.12,
                            height: screenWidth * 0.12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: !canUsePhone
                                  ? Colors.grey
                                  : Color(0xFF2C73D9), // Disabled color
                            ),
                          ),
                          if (_isLoading &&
                              _selectedMethod == ConfirmationMethod.phone)
                            SizedBox(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          else
                            Icon(
                              Icons.phone,
                              color: Colors.white,
                              size: screenWidth * 0.06,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Error Message Display ---
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}