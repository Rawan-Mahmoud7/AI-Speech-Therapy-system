import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

class ExerciseScreenR extends StatefulWidget {
  const ExerciseScreenR({super.key});

  @override
  State<ExerciseScreenR> createState() => _ExerciseScreenRState();
}

class _ExerciseScreenRState extends State<ExerciseScreenR> {
  late VideoPlayerController _controller;

  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/videos/raa.mp4')
      ..initialize().then((_) {
        setState(() {});
      });

    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> openCamera() async {
    final XFile? image =
    await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      print("📸 R Image captured: ${image.path}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                const SizedBox(height: 25),

                const Text(
                  "تمارين اهتزاز اللسان",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6E9F99),
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  "( صوت الراء )",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF6E9F99),
                  ),
                ),

                const SizedBox(height: 30),

                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "✋ التعليمات",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                _buildInstruction(
                  "ارفع طرف اللسان ليلامس اللثة العليا خلف الأسنان الأمامية",
                  "1",
                ),
                const SizedBox(height: 12),
                _buildInstruction("اترك فجوة صغيرة لمرور الهواء", "2"),
                const SizedBox(height: 12),
                _buildInstruction("كرر ( أرررر )", "3"),

                const SizedBox(height: 30),

                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color(0xFF158F7A),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _controller.value.isInitialized
                        ? AspectRatio(
                      aspectRatio: 1,
                      child: VideoPlayer(_controller),
                    )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),

                const SizedBox(height: 15),

                IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    size: 35,
                    color: Color(0xFF158F7A),
                  ),
                  onPressed: () {
                    setState(() {
                      _controller.value.isPlaying
                          ? _controller.pause()
                          : _controller.play();
                    });
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF158F7A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "إعادة التسجيل",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[200],
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      size: 35,
                      color: Colors.black,
                    ),
                    onPressed: openCamera,
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

  Widget _buildInstruction(String text, String number) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 14,
          backgroundColor: Colors.green,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}