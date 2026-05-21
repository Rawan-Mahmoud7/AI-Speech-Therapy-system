import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  String? _filePath;

  // =========================
  // 🎤 START RECORDING
  // =========================
  Future<String?> startRecording() async {
    try {
      if (await _recorder.hasPermission()) {

        final dir = await getTemporaryDirectory();

        _filePath =
        "${dir.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.wav";

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: _filePath!,
        );

        print("🎙 START PATH: $_filePath");

        return _filePath;
      }

      print("❌ NO MICROPHONE PERMISSION");
      return null;

    } catch (e) {
      print("❌ START ERROR: $e");
      return null;
    }
  }

  // =========================
  // 🛑 STOP RECORDING
  // =========================
  Future<String?> stopRecording() async {
    try {
      await _recorder.stop();

      print("🛑 STOPPED RECORDING");
      print("📁 FILE PATH: $_filePath");

      return _filePath; // 🔥 المهم جدًا
    } catch (e) {
      print("❌ STOP ERROR: $e");
      return null;
    }
  }
}