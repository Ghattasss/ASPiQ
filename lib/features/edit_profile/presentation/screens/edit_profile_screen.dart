/*import 'dart:io';
import 'package:flutter/material.dart';
// --- لا نحتاج Bloc/Cubit هنا ---
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
// --- لا نحتاج intl هنا حاليًا ---
// import 'package:intl/intl.dart';

// --- استيراد AuthService ---
import 'package:myfinalpro/auth_services.dart'; // <-- تأكدي من المسار الصحيح

// --- استيراد الويدجت المخصص ---
import '../../../../widget/custom_profile_text_field.dart'; // <-- تأكدي من المسار الصحيح

// --- استيراد شاشة تغيير كلمة المرور (إذا لزم الأمر) ---
// import 'package:my_app/features/auth/presentation/screens/change_password_screen.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // --- Controllers ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _doctorIdController = TextEditingController();
  final TextEditingController _childDobController = TextEditingController(text: 'غير متوفر');
  final TextEditingController _usernameController = TextEditingController(text: 'غير متوفر');
  final TextEditingController _phoneEmailController = TextEditingController(text: 'غير متوفر');

  // --- متغيرات الحالة المحلية ---
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _profileImageUrl = 'assets/images/placeholder.png';
  File? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _doctorIdController.dispose();
    _childDobController.dispose();
    _usernameController.dispose();
    _phoneEmailController.dispose();
    super.dispose();
  }

  // --- دالة جلب بيانات المستخدم ---
  Future<void> _loadUserProfileData() async {
    // ... (نفس كود الدالة من الرد السابق، تستدعي AuthService.getUserProfile) ...
     setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('User not authenticated');
      final result = await AuthService.getUserProfile(token);
      if (mounted && result['success'] == true && result['data'] is Map<String, dynamic>) {
        final profileData = result['data'] as Map<String, dynamic>;
        setState(() {
          _nameController.text = profileData['name'] ?? '';
          _surnameController.text = profileData['surname'] ?? '';
          _doctorIdController.text = profileData['doctor_ID']?.toString() ?? '';
          _profileImageUrl = profileData['image_'] ?? 'assets/images/placeholder.png';
          // --- يمكن تحديث الحقول الأخرى هنا إذا أضافها الـ Backend ---
          // _usernameController.text = profileData['email'] ?? 'غير متوفر';
          // _phoneEmailController.text = profileData['phone'] ?? 'غير متوفر';
          // ...
          _isLoading = false;
        });
      } else { throw Exception(result['message'] ?? 'Failed to load profile'); }
    } catch (e) {
      print("Error in _loadUserProfileData: $e");
      if (mounted) setState(() { _errorMessage = "فشل تحميل بيانات الملف الشخصي: $e"; _isLoading = false; });
    }
  }

  // --- دالة اختيار الصورة ---
  Future<void> _pickImage() async {
    if (_isSaving) return;
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null) { // <-- لا نحتاج التحقق من mounted هنا لأننا سنقوم بـ await لـ _uploadPicture
        final fileToUpload = File(image.path);
        setState(() { _selectedImageFile = fileToUpload; }); // عرض الصورة المختارة مؤقتًا
        await _uploadPicture(fileToUpload); // استدعاء الرفع والانتظار
      }
    } catch (e) {
      print("Error picking image: $e");
      if (mounted) { setState(() { _errorMessage = "حدث خطأ أثناء اختيار الصورة: $e"; }); }
    }
  }

  // --- دالة رفع الصورة ---
  Future<void> _uploadPicture(File imageFile) async {
     setState(() { _isSaving = true; _errorMessage = null; });
     try {
        final token = await AuthService.getToken();
         if (token == null) throw Exception('User not authenticated');
        final result = await AuthService.uploadProfilePicture(token, imageFile);
        if (mounted && result['success'] == true && result['newImageUrl'] != null) {
            setState(() {
               _profileImageUrl = result['newImageUrl'];
               _selectedImageFile = null; // مسح الملف المؤقت
               _isSaving = false;
            });
             ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar( const SnackBar(content: Text("تم تحديث الصورة بنجاح"), backgroundColor: Colors.green));
        } else { throw Exception(result['message'] ?? 'Failed to upload picture'); }
     } catch (e) {
         print("Error uploading picture: $e");
         if (mounted) setState(() { _errorMessage = "فشل تحديث الصورة: $e"; _isSaving = false; _selectedImageFile = null; });
     }
  }

  // --- دالة حفظ التغييرات ---
  Future<void> _saveProfileChanges() async {
    if (_isSaving || _isLoading) return;
    // يمكنك إضافة التحقق من الفورم هنا إذا استخدمتِ GlobalKey<FormState>
    setState(() { _isSaving = true; _errorMessage = null; });
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('User not authenticated');
      final String name = _nameController.text.trim();
      final String surname = _surnameController.text.trim();
      final int? doctorId = int.tryParse(_doctorIdController.text.trim());
      if (name.isEmpty || surname.isEmpty) throw Exception("الاسم واللقب مطلوبان");

      final Map<String, dynamic> profileData = {
        'Name': name, // تأكدي من الاسم الصحيح الذي يقبله API التحديث
        'Surname': surname,
      };
      if (doctorId != null) profileData['Doctor_ID'] = doctorId;

      final result = await AuthService.updateUserProfile(token, profileData);

      if (mounted && result['success'] == true) {
         setState(() { _isSaving = false; });
          ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar( const SnackBar(content: Text("تم حفظ التغييرات بنجاح"), backgroundColor: Colors.green));
         await _loadUserProfileData(); // إعادة تحميل البيانات
      } else { throw Exception(result['message'] ?? 'Failed to save profile'); }
    } catch (e) {
      print("Error saving profile: $e");
      if (mounted) setState(() { _errorMessage = "فشل حفظ التغييرات: $e"; _isSaving = false; });
    }
  }


  @override
  Widget build(BuildContext context) {
    // ... (نفس كود بناء الواجهة من الرد السابق، مع تعديل بسيط لـ _buildProfilePictureWidget) ...
     final screenWidth = MediaQuery.of(context).size.width; // قد نحتاجه للصورة
     final screenHeight = MediaQuery.of(context).size.height; // قد نحتاجه للمسافات

     if (_isLoading) { /* ... عرض مؤشر التحميل ... */ }

     return Scaffold( /* ... AppBar ... */
         backgroundColor: Colors.grey[50],
         body: SafeArea(
           child: SingleChildScrollView(
             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 15),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                  SizedBox(height: screenHeight * 0.01),
                 // --- عرض الصورة الشخصية ---
                 _buildProfilePictureWidget(context), // <-- تم تعديل استدعاء الدالة
                 SizedBox(height: screenHeight * 0.04),

                 // --- عرض رسالة الخطأ ---
                 if (_errorMessage != null) 
                  Padding( // <--- Widget لعرض الخطأ مع padding
                     padding: const EdgeInsets.only(bottom: 15.0), // مسافة سفلية قبل الحقول
                     child: Text(
                       _errorMessage!, // عرض رسالة الخطأ
                       style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), // تنسيق مميز للخطأ
                       textAlign: TextAlign.center, // توسيط النص
                     ),
                   ),

                 // --- حقول الإدخال ---
                 // (نفس الحقول كما في الرد السابق، مربوطة بالـ controllers الصحيحة)
                 CustomProfileTextField( label: "اسم الطفل", hint: "أدخل اسم طفلك", controller: _nameController, readOnly: _isSaving, ),
                 CustomProfileTextField( label: "اللقب", hint: "أدخل اللقب", controller: _surnameController, readOnly: _isSaving, ),
                 CustomProfileTextField( label: "رقم تعريف الأخصائي (اختياري)", hint: "ادخل رقم تعريف الأخصائي", controller: _doctorIdController, keyboardType: TextInputType.number, readOnly: _isSaving,),
                 CustomProfileTextField( label: "تاريخ ميلاد الطفل", hint: "", controller: _childDobController, readOnly: true, suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey), ),
                 CustomProfileTextField( label: "اسم المستخدم (الإيميل)", hint: "", controller: _usernameController, readOnly: true, suffixIcon: const Icon(Icons.person_outline, color: Colors.grey), ),
                 CustomProfileTextField( label: "رقم الهاتف", hint: "", controller: _phoneEmailController, readOnly: true, suffixIcon: const Icon(Icons.phone_outlined, color: Colors.grey), ),
                 CustomProfileTextField( label: "كلمة السر", hint: "", controller: TextEditingController(text:"************"), obscureText: true, readOnly: true, suffixIcon: const Icon(Icons.lock_outline, color: Colors.grey), ),
               

                 Padding(padding: const EdgeInsets.all(8.0), // <-- أضيفي padding هنا بقيمة مناسبة
                    child: Text("/* ... رابط تغيير كلمة المرور ... */"),
                        ),

                  SizedBox(height: screenHeight * 0.04),
                  // --- زر الحفظ ---
                  _buildSaveButtonWidget(context), // <-- تم تعديل استدعاء الدالة
                  SizedBox(height: screenHeight * 0.04),
               ],
             ),
           ),
         ),
     );
  }

  // --- دالة بناء واجهة الصورة الشخصية (مُبسّطة) ---
  Widget _buildProfilePictureWidget(BuildContext context) {
     final screenWidth = MediaQuery.of(context).size.width; // نستخدم screenWidth هنا
     ImageProvider displayImage;
     if (_selectedImageFile != null && !_isSaving) {
       displayImage = FileImage(_selectedImageFile!);
     } else if (_profileImageUrl.startsWith('http')) {
       displayImage = NetworkImage(_profileImageUrl);
     } else {
       displayImage = const AssetImage('assets/images/placeholder.png');
     }

     return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
             radius: screenWidth * 0.18,
             backgroundColor: Colors.grey.shade200,
              backgroundImage: displayImage,
             onBackgroundImageError: (exception, stackTrace) { /* ... */ },
             child: _isSaving // عرض مؤشر التحميل فقط أثناء الحفظ/الرفع
                ? Container( decoration: BoxDecoration( color: Colors.black38, shape: BoxShape.circle, ), child: const Center(child: CircularProgressIndicator(color: Colors.white)), )
                : null,
           ),
          Positioned(
            right: 0, bottom: 0,
            child: Material( // استخدام Material لتأثير الضغط
              color: const Color(0xFF2C73D9),
              shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                 splashColor: Colors.white.withOpacity(0.3),
                 onTap: _isSaving ? null : _pickImage, // <-- استدعاء _pickImage
                 child: Container(
                   padding: const EdgeInsets.all(6),
                   child: Icon( Icons.camera_alt, size: screenWidth * 0.055, color: Colors.white, ),
                 ),
               ),
            ),
          ),
        ],
      ),
    );
  }

   // --- دالة بناء زر الحفظ (مُبسّطة) ---
   Widget _buildSaveButtonWidget(BuildContext context) {
     return ElevatedButton(
          onPressed: _isLoading || _isSaving ? null : _saveProfileChanges,
          style: ElevatedButton.styleFrom( backgroundColor: const Color(0xFF2C73D9), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(10.0), ), elevation: 2, disabledBackgroundColor: Colors.grey.shade400, ),
           child: _isSaving
              ? const SizedBox( width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3), )
              : const Text( "حفظ التغييرات", style: TextStyle( color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, ), ),
        );
   }
}*/