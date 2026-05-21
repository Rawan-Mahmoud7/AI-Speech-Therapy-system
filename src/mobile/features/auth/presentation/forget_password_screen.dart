import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import 'auth_header.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [

            const AuthHeader(title: "نسيت كلمة المرور"),

            const SizedBox(height: 40),

            const Text(
              "عنوان البريد",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            const Text(
              "أدخل عنوان البريد الإلكتروني الخاص بحسابك",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: TextField(
                controller: emailController, // 🔥 مهم
                decoration: const InputDecoration(
                  hintText: "البريد الإلكتروني",
                  filled: true,
                  fillColor: Color(0xFFE6F2F0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF158F7A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {

                    var result = await ApiService.sendOtp(
                      emailController.text.trim(),
                    );

                    if (result['message'] != null) {

                      // 🔥 نبعّت الإيميل للشاشة اللي بعدها
                      Navigator.pushNamed(
                        context,
                        AppRoutes.verifyCode,
                        arguments: emailController.text.trim(),
                      );

                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("فشل إرسال الكود ❌"),
                        ),
                      );
                    }

                  },
                  child: const Text(
                    "استعادة كلمة المرور",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}