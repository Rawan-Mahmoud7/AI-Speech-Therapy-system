import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/api_service.dart';

class LevelFourScreenS extends StatefulWidget {
  const LevelFourScreenS({super.key});

  @override
  State<LevelFourScreenS> createState() => _LevelFourScreenSState();
}

class _LevelFourScreenSState extends State<LevelFourScreenS> {

  final AudioService audio = AudioService();

  bool isRecording = false;
  String? path;

  int sessionId = -1;

  int level = 0;

  // 🔥 أهم تعديل
  late String letter;

  final List<String> sentences = [
    "سمكة سريعة.",
    "سيارة سوداء.",
    "مدرسة سعيدة."
  ];

  int sentenceIndex = 0;

  int successStreak = 0;
  final int requiredSuccess = 3;

  String get currentSentence => sentences[sentenceIndex];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    sessionId = args?["sessionId"] ?? -1;
    level = args?["level"] ?? 0;
    letter = args?["letter"] ?? "s";
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final int level = args?["level"] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [

                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6ECE8),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  "المرحلة ${level + 1}",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF158F7A),
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  "إقرأ المقطع التالي بوضوح",
                  style: TextStyle(fontSize: 20),
                ),

                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    currentSentence,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),

                const SizedBox(height: 40),

                const Text(
                  "سجل المقطع هنا",
                  style: TextStyle(fontSize: 22),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: () async {
                    if (!isRecording) {
                      path = await audio.startRecording();
                      setState(() => isRecording = true);
                    } else {
                      path = await audio.stopRecording();
                      setState(() => isRecording = false);

                      if (path == null) return;

                      await handleRecording(path!);
                    }
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD6ECE8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      size: 50,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  "الجملة الحالية:\n$currentSentence\nنجاح: $successStreak / $requiredSuccess",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> handleRecording(String path) async {
    try {
      final isCorrect = await evaluateAudio(path);

      if (!mounted) return;

      if (isCorrect) {
        successStreak++;

        if (successStreak >= requiredSuccess) {
          sentenceIndex++;
          successStreak = 0;

          if (sentenceIndex >= sentences.length) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt("currentLevel", 4);

            final result = await Navigator.pushNamed(
              context,
              AppRoutes.success,
            );

            if (result == true) {
              Navigator.pop(context, true);
            }

            return;

            return;
          }
        }
      } else {
        successStreak = 0;

        setState(() {});

        // 🔥 أهم تعديل (منع الرجوع للراء)
        await Navigator.pushNamed(
          context,
          AppRoutes.failure,
          arguments: {
            "letter": letter,
          },
        );

        return;
      }

      setState(() {});
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<bool> evaluateAudio(String path) async {
    try {
      if (sessionId == -1) return false;

      final audioResponse = await ApiService.uploadAudio(
        path: path,
        sessionId: sessionId,
        level: level + 1,
        targetPhoneme: "س",
        expectedText: currentSentence,
      );

      final audioId = audioResponse["data"]?["id"];
      if (audioId == null) return false;

      final response = await ApiService.analyze(audioId);

      final data = response["data"];
      if (data == null) return false;

      return data["is_correct"] == true ||
          data["is_correct"] == 1 ||
          data["is_correct"].toString() == "true";

    } catch (e) {
      print("Error: $e");
      return false;
    }
  }
}