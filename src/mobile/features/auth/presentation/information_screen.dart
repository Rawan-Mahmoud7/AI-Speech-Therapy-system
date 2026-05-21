import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/api_service.dart';

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key});

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {

  String? gender;
  String? stutterType;

  final TextEditingController age = TextEditingController();

  @override
  void initState() {
    super.initState();
    initSession();
  }

  Future<void> initSession() async {
    await ApiService.loadToken();

    // منع تكرار إنشاء session
    if (ApiService.currentSessionId == null) {

    }

    print("📌 SESSION ID: ${ApiService.currentSessionId}");
  }

  @override
  Widget build(BuildContext context) {

    final args = ModalRoute.of(context)?.settings.arguments;
    final bool isEdit = args is bool ? args : false;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: isEdit
          ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      )
          : null,

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const SizedBox(height: 20),

              const Text(
                "معلوماتك الشخصية",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              _buildGreenDropdown(
                "الجنس",
                gender,
                ["ذكر", "أنثى"],
                    (value) => setState(() => gender = value),
              ),

              const SizedBox(height: 15),

              _buildGreenField("العمر", age),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: stutterType,
                decoration: InputDecoration(
                  hintText: "نوع اللدغة",
                  filled: true,
                  fillColor: const Color(0xFFE6F4F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),

                items: const [
                  DropdownMenuItem(
                    value: "s",
                    child: Text("لدغة حرف السين"),
                  ),
                  DropdownMenuItem(
                    value: "r",
                    child: Text("لدغة حرف الراء"),
                  ),
                ],

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "من فضلك اختاري نوع اللدغة";
                  }
                  return null;
                },

                onChanged: (value) {
                  setState(() {
                    stutterType = value;
                  });
                },
              ),

              const SizedBox(height: 35),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF158F7A),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () async {

                  if (isEdit) {
                    Navigator.pop(context);
                  } else {
                    if (stutterType == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("من فضلك اختر نوع اللدغة"),
                        ),
                      );
                      return;
                    }

                    var result = await ApiService.updateProfile(
                      age: int.parse(age.text),
                      gender: (gender == "ذكر")
                          ? "male"
                          : (gender == "أنثى")
                          ? "female"
                          : "",
                      type: stutterType!,
                    );

                    if (result['message'] != null) {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.levels,
                        arguments: stutterType,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("فشل حفظ البيانات ❌")),
                      );
                    }
                  }
                },
                child: Text(
                  isEdit ? "تعديل البيانات" : "حفظ البيانات",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

  Widget _buildGreenField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFE6F4F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGreenDropdown(
      String hint,
      String? value,
      List<String> items,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFE6F4F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(
        value: e,
        child: Text(e),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }
}