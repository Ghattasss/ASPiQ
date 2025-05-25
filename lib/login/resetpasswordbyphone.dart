import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myfinalpro/registration/Code verification.dart';

class Resetpasswordbyphone extends StatefulWidget {
  const Resetpasswordbyphone({super.key});

  @override
  State<Resetpasswordbyphone> createState() => _ResetpasswordbyphoneState();
}

class _ResetpasswordbyphoneState extends State<Resetpasswordbyphone> {
  TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _sendOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Using Send-OTP endpoint for password reset
      final response = await http.post(
        Uri.parse('http://aspiq.runasp.net/api/auth/Send-OTP'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'Email': _phoneController.text, // According to API, need Email field
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Successfully sent OTP
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CodeVerification(
              email: _phoneController.text,
              token: responseData['token'], // Use the token from response
            ),
          ),
        );
      } else {
        // Handle error
        setState(() {
          _errorMessage = responseData['message'] ??
              'Failed to send OTP. Please try again.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage =
        'Network error. Please check your connection and try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 25),
          child: Text(
            "إعادة تعيين كلمة المرور",
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
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
              SizedBox(height: screenHeight * 0.09),
              Text(
                "أدخل رقم الهاتف لاستعادة كلمة المرور",
                style: TextStyle(
                  color: Color(0xFF2C73D9),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  fillColor: const Color(0xFFE6E9EA),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE6E9EA)),
                  ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: screenHeight * 0.07),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2C73D9),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "متابعة",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}