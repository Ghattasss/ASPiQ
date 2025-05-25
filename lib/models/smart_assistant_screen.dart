// lib/screens/smart_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// تأكد من استيراد الملفات بشكل صحيح
import '../models/chat_message.dart'; // <-- استيراد ChatMessage
import 'chat_storage_helper.dart'; // <-- استيراد ChatStorageHelper
// import '../screens/assessment_screen.dart'; // إذا كنت تستخدمه

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = []; // <-- ابدأ بقائمة فارغة ليتم تحميلها
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isHistoryLoading = true; // <-- متغير جديد لتتبع تحميل المحادثة

  // ... (باقي الألوان ورابط الـ API كما هي)
  final Color userMessageColor = const Color(0xFF007AFF);
  final Color botMessageColor = const Color(0xFFE5E5EA);
  final Color appBarTextColor = const Color(0xFF007AFF);
  final Color backgroundColor = Colors.white;
  final Color userTextColor = Colors.white;
  final Color botTextColor = Colors.black87;
  final Color errorTextColor = Colors.red.shade700;
  final String _apiUrl =
      "https://chatbot-1064665840424.us-central1.run.app/ask";


  @override
  void initState() {
    super.initState();
    _loadChatHistory(); // <-- استدعاء تحميل المحادثة عند بدء التشغيل
  }

  // --- ***** دالة جديدة لتحميل المحادثة السابقة ***** ---
  Future<void> _loadChatHistory() async {
    final loadedMessages = await ChatStorageHelper.loadMessages();
    if (mounted) {
      setState(() {
        if (loadedMessages != null && loadedMessages.isNotEmpty) {
          _messages.addAll(loadedMessages);
        } else {
          // إذا لم تكن هناك محادثة محفوظة، أضف رسالة الترحيب الافتراضية
          _messages.add(ChatMessage(
            text: "مرحباً! أنا المساعد الذكي، كيف يمكنني مساعدتك اليوم؟",
            isUserMessage: false,
          ));
        }
        _isHistoryLoading = false; // تم الانتهاء من التحميل
      });
      _scrollToBottom(); // التمرير للأسفل بعد تحميل الرسائل
    }
  }
  // ----------------------------------------------------

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async { // <-- إضافة async
    final String messageText = text.trim();
    if (messageText.isEmpty || _isLoading) {
      return;
    }

    _textController.clear();
    final userMessage = ChatMessage(text: messageText, isUserMessage: true); // إنشاء الرسالة

    setState(() {
      _messages.add(userMessage); // إضافة رسالة المستخدم
      _isLoading = true;
    });
    _scrollToBottom();

    await ChatStorageHelper.saveMessages(_messages); // <-- حفظ المحادثة بعد إضافة رسالة المستخدم

    _getBotResponse(messageText);
  }

  Future<void> _getBotResponse(String userMessage) async {
    ChatMessage? botMessage; // متغير لتخزين رسالة البوت
    try {
      print("Attempting to POST to: $_apiUrl with user message: $userMessage");

      final response = await http
          .post(
        Uri.parse(_apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'accept': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'text': userMessage,
        }),
      )
          .timeout(const Duration(seconds: 45));

      if (mounted) {
        if (response.statusCode == 200) {
          final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
          final String botReply = responseBody['response'] ??
              responseBody['answer'] ??
              responseBody['reply'] ??
              responseBody['text'] ??
              responseBody['message'] ??
              'لم أجد إجابة واضحة في الرد.';
          botMessage = ChatMessage(text: botReply, isUserMessage: false); // إنشاء رسالة البوت
        } else {
          String errorBody = '';
          try {
            errorBody = utf8.decode(response.bodyBytes);
          } catch (e) {
            errorBody = response.reasonPhrase ?? 'خطأ غير معروف';
          }
          botMessage = ChatMessage( // إنشاء رسالة الخطأ
            text: 'حدث خطأ ${response.statusCode}: $errorBody',
            isUserMessage: false,
            isError: true,
          );
          print('API Error: ${response.statusCode} - Body: $errorBody');
        }
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        botMessage = ChatMessage( // إنشاء رسالة الخطأ
          text: 'انتهت مهلة الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
          isUserMessage: false,
          isError: true,
        );
      }
      print('API Error: Request timed out');
    } catch (e) {
      if (mounted) {
        botMessage = ChatMessage( // إنشاء رسالة الخطأ
          text: 'حدث خطأ غير متوقع أثناء الاتصال: $e',
          isUserMessage: false,
          isError: true,
        );
      }
      print('API Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (botMessage != null) {
            _messages.add(botMessage!); // إضافة رسالة البوت أو الخطأ إلى القائمة
          }
        });
        if (botMessage != null) {
          await ChatStorageHelper.saveMessages(_messages); // <-- حفظ المحادثة بعد إضافة رسالة البوت/الخطأ
        }
      }
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- ***** دالة لمسح المحادثة (اختياري) ***** ---
  Future<void> _clearChatConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف', textDirection: TextDirection.rtl),
          content: const Text('هل أنت متأكد أنك تريد حذف سجل المحادثة بالكامل؟ هذا الإجراء لا يمكن التراجع عنه.', textDirection: TextDirection.rtl),
          actions: <Widget>[
            TextButton(
              child: const Text('إلغاء'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await ChatStorageHelper.clearMessages();
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.add(ChatMessage( // إعادة إضافة رسالة الترحيب
            text: "مرحباً! أنا المساعد الذكي، كيف يمكنني مساعدتك اليوم؟",
            isUserMessage: false,
          ));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف سجل المحادثة بنجاح.', textDirection: TextDirection.rtl)),
        );
      }
    }
  }
  // ---------------------------------------------------


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          title: Text(
            'المساعد الذكي',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: appBarTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
          actions: [ // <-- إضافة زر لمسح المحادثة
            IconButton(
              icon: Icon(Icons.delete_outline, color: appBarTextColor),
              tooltip: 'مسح المحادثة',
              onPressed: _clearChatConfirmation,
            ),
          ],
        ),
        body: _isHistoryLoading // <-- عرض مؤشر تحميل أثناء جلب المحادثة
            ? Center(child: CircularProgressIndicator(color: userMessageColor))
            : Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isLoading && index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
            Divider(height: 1.0, color: Colors.grey.shade300),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  // ... (باقي دوال _buildMessageBubble, _buildTypingIndicator, _buildTextComposer كما هي)
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUserMessage;
    final isError = message.isError;

    return Row(
      mainAxisAlignment:
      isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          decoration: BoxDecoration(
            color: isError
                ? Colors.red.shade100
                : (isUser ? userMessageColor : botMessageColor),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20.0),
              topRight: const Radius.circular(20.0),
              bottomLeft: Radius.circular(isUser ? 0 : 20.0),
              bottomRight: Radius.circular(isUser ?20.0 : 0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: isError
                  ? errorTextColor
                  : (isUser ? userTextColor : botTextColor),
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
          decoration: BoxDecoration(
            color: botMessageColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
              bottomRight: Radius.circular(20.0),
              bottomLeft: Radius.circular(0),
            ),
          ),
          child: const SizedBox(
            width: 40,
            height: 20,
            child: RepaintBoundary(child: ThreeDotsLoadingIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildTextComposer() {
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 8.0,
        left: 8.0,
        right: 8.0,
        top: 8.0,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: _isLoading ? null : _handleSubmitted,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText:
                _isLoading ? "يرجى الانتظار..." : "اكتب رسالتك هنا...",
                hintStyle: TextStyle(
                  color:
                  _isLoading ? Colors.grey.shade400 : Colors.grey.shade500,
                  fontFamily: 'Cairo',
                ),
                hintTextDirection: TextDirection.rtl,
                filled: true,
                fillColor:
                _isLoading ? Colors.grey.shade50 : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 20.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(
                    color: userMessageColor.withOpacity(0.5),
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                color: _isLoading ? Colors.grey.shade600 : Colors.black87,
              ),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
            ),
          ),
          const SizedBox(width: 8.0),
          Material(
            color: _isLoading ? Colors.grey : userMessageColor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap:
              _isLoading
                  ? null
                  : () => _handleSubmitted(_textController.text),
              child: const Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class ThreeDotsLoadingIndicator extends StatefulWidget {
  const ThreeDotsLoadingIndicator({super.key});
  @override
  State<ThreeDotsLoadingIndicator> createState() =>
      _ThreeDotsLoadingIndicatorState();
}

class _ThreeDotsLoadingIndicatorState extends State<ThreeDotsLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _animation1 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -6.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -6.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6)),
    );

    _animation2 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -6.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -6.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.7)),
    );

    _animation3 = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -6.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -6.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceEvenly,
          children: [
            Transform.translate(
              offset: Offset(0, _animation1.value),
              child: _buildDot(),
            ),
            Transform.translate(
              offset: Offset(0, _animation2.value),
              child: _buildDot(),
            ),
            Transform.translate(
              offset: Offset(0, _animation3.value),
              child: _buildDot(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDot() {
    return Container(
      width: 8.0,
      height: 8.0,
      decoration: BoxDecoration(
        color: Colors.grey.shade500,
        shape: BoxShape.circle,
      ),
    );
  }
}