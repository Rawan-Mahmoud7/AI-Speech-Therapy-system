import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFE1DE),

      appBar: AppBar(
        backgroundColor: const Color(0xFFBFE1DE),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "كيفية الاستخدام",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [

              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "تعليمات استخدام التطبيق",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF158F7A),
                          ),
                        ),

                        SizedBox(height: 25),

                        Text(
                          "١- اختر المرحلة المفتوحة لك من صفحة المستويات",
                          style: TextStyle(fontSize: 18),
                        ),

                        SizedBox(height: 18),

                        Text(
                          "٢- استمع جيدًا إلى النطق الصحيح قبل التسجيل",
                          style: TextStyle(fontSize: 18),
                        ),

                        SizedBox(height: 18),

                        Text(
                          "٣- اضغط على زر الميكروفون لبدء التسجيل",
                          style: TextStyle(fontSize: 18),
                        ),

                        SizedBox(height: 18),

                        Text(
                          "٤- حاول نطق الحرف أو الكلمة بوضوح",
                          style: TextStyle(fontSize: 18),
                        ),

                        SizedBox(height: 18),

                        Text(
                          "٥- عند النجاح عدة مرات متتالية سيتم فتح المرحلة التالية",
                          style: TextStyle(fontSize: 18),
                        ),

                        SizedBox(height: 18),

                        Text(
                          "٦- يمكنك متابعة تقدمك من صفحة المستويات",
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF158F7A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "العودة إلى المستويات",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}