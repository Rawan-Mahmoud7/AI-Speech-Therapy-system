import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: Directionality(
            textDirection: TextDirection.rtl,
            child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                      const SizedBox(height: 40),

                  Image.asset(
                    'assets/images/signup.jpg',
                    height: 120,
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "سجل الدخول إلى حسابك",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildTextField(
                    "البريد الإلكتروني",
                    controller: emailController,
                  ),

                  const SizedBox(height: 20),

                  _buildTextField(
                    "كلمة المرور",
                    isPassword: true,
                    controller: passwordController,
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        );
                      },
                      child: const Text(
                        "نسيت كلمة المرور؟",
                        style: TextStyle(
                          color: Color(0xFF158F7A),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  _buildButton("تسجيل الدخول", () async {
                    var result = await ApiService.login(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    );

                    if (result['token'] != null) {

                      // ✅ إضافة فقط للتأكد من الـ id
                      print("USER ID: ${ApiService.userId}");
                      print("USER NAME: ${ApiService.userName}");
                      print("ROLE: ${ApiService.role}");

                      Navigator.pushReplacementNamed(
                          context, AppRoutes.information);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("خطأ في تسجيل الدخول ❌"),
                        ),
                      );
                    }
                  }),


                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.signup);
                          },
                          child: RichText(
                            text: const TextSpan(
                              text: "لا تمتلك حساب؟ ",
                              style: TextStyle(color: Colors.black),
                              children: [
                                TextSpan(
                                  text: "إنشاء حساب",
                                  style: TextStyle(
                                    color: Colors.teal,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                  ),
                ),
            ),
        ),
    );
  }

  Widget _buildTextField(
      String hint, {
        bool isPassword = false,
        TextEditingController? controller,
      }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: const InputDecoration(
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.teal),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
      ).copyWith(hintText: hint),
    );
  }

  Widget _buildButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}