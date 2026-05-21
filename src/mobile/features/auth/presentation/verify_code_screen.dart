import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';
import 'auth_header.dart';

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {

  final List<TextEditingController> controllers =
  List.generate(6, (_) => TextEditingController());

  String email = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    email = ModalRoute.of(context)?.settings.arguments as String? ?? "";
  }

  String getOtp() {
    return controllers.map((e) => e.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
                children: [

                const AuthHeader(title: "التحقق من البريد الإلكتروني"),

            const SizedBox(height: 40),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    "احصل على الرمز الخاص بك",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 8),

                  Text(
                    "الرجاء إدخال الرمز المكون من ستة أرقام",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                    (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 45,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F2F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: controllers[index],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: const InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                    ),
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
                        ),
                        onPressed: () async {

                          var result = await ApiService.verifyOtp(
                            email,
                            getOtp(),
                          );

                          if (result['message'] != null) {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.resetPassword,
                              arguments: {
                                "email": email,
                                "otp": getOtp(),
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("كود غير صحيح ❌")),
                            );
                          }
                        },
                      child: const Text(
                        "التحقق والمتابعة",
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