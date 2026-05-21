import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  List doctors = [];
  String? selectedDoctor;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    try {
      var data = await ApiService.getDoctors();

      print("DOCTORS RESPONSE: $data");

      setState(() {
        doctors = (data is List) ? data : [];
        isLoading = false;
      });

    } catch (e) {
      print("❌ LOAD DOCTORS ERROR: $e");
      setState(() {
        doctors = [];
        isLoading = false;
      });
    }
  }

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
              children: [

                const SizedBox(height: 40),

                Image.asset(
                  'assets/images/signup.jpg',
                  height: 120,
                ),

                const SizedBox(height: 30),

                const Text(
                  "قم بإنشاء حسابك",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                _buildTextField("الاسم", controller: nameController),
                const SizedBox(height: 20),

                _buildTextField("البريد الإلكتروني", controller: emailController),
                const SizedBox(height: 20),

                _buildTextField("كلمة المرور",
                    isPassword: true, controller: passwordController),
                const SizedBox(height: 20),

                _buildTextField("تأكيد كلمة المرور",
                    isPassword: true, controller: confirmPasswordController),
                const SizedBox(height: 20),

                isLoading
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                  value: selectedDoctor,
                  items: doctors.map<DropdownMenuItem<String>>((doc) {
                    final id = doc['id'];

                    return DropdownMenuItem<String>(
                      value: id != null ? id.toString() : null,
                      child: Text(
                        doc['name'] ??
                            doc['doctor_name'] ??
                            doc['full_name'] ??
                            doc['username'] ??
                            doc['user']?['name'] ??
                            'Doctor',
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDoctor = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: "اسم الدكتور",
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                _buildButton("إنشاء حساب", () async {

                  if (passwordController.text != confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("كلمتا المرور غير متطابقتين ❌")),
                    );
                    return;
                  }

                  if (selectedDoctor == null || selectedDoctor!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("اختاري دكتور الأول ❗️")),
                    );
                    return;
                  }

                  int doctorId = int.tryParse(selectedDoctor!) ?? 0;

                  var result = await ApiService.register(
                    nameController.text.trim().isEmpty
                        ? "user"
                        : nameController.text.trim(),
                    emailController.text.trim(),
                    passwordController.text.trim(),
                    confirmPasswordController.text.trim(),
                    int.parse(selectedDoctor ?? '0'),
                  );

                  print("REGISTER RESULT: $result");

                  if (result['statusCode'] == 200 || result['statusCode'] == 201) {

                    print("🚀 NAVIGATING...");

                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.information,
                      arguments: nameController.text,
                    );

                  } else {

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? "فشل إنشاء الحساب ❌"),
                      ),
                    );

                  }
                }),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "تمتلك حساب؟ ",
                      style: TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: "تسجيل الدخول",
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

  Widget _buildTextField(String hint,
      {bool isPassword = false, TextEditingController? controller}) {
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