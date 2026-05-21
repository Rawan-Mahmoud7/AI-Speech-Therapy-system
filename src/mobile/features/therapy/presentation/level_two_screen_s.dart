import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/api_service.dart';

class LevelTwoScreenS extends StatefulWidget {
  const LevelTwoScreenS({super.key});

  @override
  State<LevelTwoScreenS> createState() => _LevelTwoScreenSState();
}

class _LevelTwoScreenSState extends State<LevelTwoScreenS>
    with TickerProviderStateMixin {

  final AudioService audio = AudioService();
  final AudioPlayer player = AudioPlayer();

  bool isRecording = false;
  String? path;

  int sessionId = -1;

  int level = 0;
  late String letter;

  final List<String> targets = ["سا", "سو", "سي"];
  int stageIndex = 0;

  int successStreak = 0;
  final int requiredSuccess = 8;

  String get currentTarget => targets[stageIndex];

  // 🔥 waves
  late AnimationController wave1;
  late AnimationController wave2;
  late AnimationController wave3;

  @override
  void initState() {
    super.initState();

    wave1 = _createWave();
    wave2 = _createWave();
    wave3 = _createWave();
  }

  AnimationController _createWave() {
    return AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map?;

    sessionId = args?["sessionId"] ?? -1;
    level = args?["level"] ?? 0;
    letter = args?["letter"] ?? "s";
  }

  @override
  void dispose() {
    wave1.dispose();
    wave2.dispose();
    wave3.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> playAudio(String file, AnimationController controller) async {
    try {
      controller
        ..reset()
        ..repeat(reverse: true);

      await player.stop();
      await player.play(AssetSource('audio/$file'));

      player.onPlayerComplete.first.then((_) {
        controller.stop();
        controller.reset();
      });

    } catch (e) {
      print("AUDIO ERROR: $e");
    }
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
                    currentTarget,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),

                const SizedBox(height: 40),

                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "النطق الصحيح للمقطع:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _buildAudioPlayer("seen_fatha.m4a", wave1),
                const SizedBox(height: 15),
                _buildAudioPlayer("seen_dama.m4a", wave2),
                const SizedBox(height: 15),
                _buildAudioPlayer("seen_kasra.m4a", wave3),

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
                  "المرحلة الحالية: $currentTarget\nنجاح: $successStreak / $requiredSuccess",
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

  Widget _buildAudioPlayer(String file, AnimationController controller) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [

          const SizedBox(width: 15),

          IconButton(
            icon: const Icon(Icons.play_arrow, size: 35),
            onPressed: () => playAudio(file, controller),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    15,
                        (index) => Container(
                      width: 4,
                      height: (index % 2 == 0 ? 40 : 20) *
                          (controller.isAnimating ? (0.5 + controller.value) : 0.3),
                      color: Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 15),
        ],
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
          stageIndex++;
          successStreak = 0;

          if (stageIndex >= targets.length) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt("currentLevel", 3);

            final result = await Navigator.pushNamed(
              context,
              AppRoutes.success,
            );

            if (result == true) {
              Navigator.pop(context, true);
            }

            return;
          }
        }
      } else {
        successStreak = 0;

        await Navigator.pushNamed(
          context,
          AppRoutes.failure,
          arguments: {
            "letter": letter,
          },
        );
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