import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;
class FullscreenVideoPlayerController extends GetxController
    with GetTickerProviderStateMixin {
  final VideoPlayerController videoController;
  final String videoUrl;

  FullscreenVideoPlayerController({
    required this.videoController,
    required this.videoUrl,
  });

  final RxBool showControls = true.obs;
  late AnimationController controlsAnimationController;
  late Animation<double> controlsAnimation;

  @override
  void onInit() {
    super.onInit();
    _initializeFullscreen();
    _initializeAnimations();
    startControlsTimer();
  }

  @override
  void onClose() {
    _restoreSystemUI();
    controlsAnimationController.dispose();
    super.onClose();
  }

  void _initializeFullscreen() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _initializeAnimations() {
    controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    controlsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: controlsAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    controlsAnimationController.forward();
  }

  Future<void> downloadVideo(BuildContext context, String videoUrl) async {
    if (videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No video URL available")),
      );
      return;
    }

    try {
      if (kIsWeb) {
        try {
          final fileName = 'ai_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
          final anchor = html.AnchorElement(href: videoUrl)
            ..setAttribute('download', fileName)
            ..setAttribute('target', '_blank')
            ..style.display = 'none';
          
          html.document.body?.children.add(anchor);
          anchor.click();
          html.document.body?.children.remove(anchor);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Download started in browser"),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          html.window.open(videoUrl, '_blank');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Video opened in new tab. Right-click to save."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Starting download...")),
      );

      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Storage permission denied"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download video: ${response.statusCode}');
      }

      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        throw Exception('Could not access storage directory');
      }

      final fileName = 'ai_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = "${dir.path}/$fileName";
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Video downloaded to: $filePath"),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      print("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void startControlsTimer() {
    // Future.delayed(const Duration(seconds: 3), () {
    //   if (showControls.value) {
    //     hideControls();
    //   }
    // });
  }

  void toggleControls() {
    showControls.value = !showControls.value;

    if (showControls.value) {
      controlsAnimationController.forward();
      startControlsTimer();
    } else {
      controlsAnimationController.reverse();
    }
  }

  void hideControls() {
    showControls.value = false;
    controlsAnimationController.reverse();
  }

  void showControlsTemporarily() {
    showControls.value = true;
    controlsAnimationController.forward();
    startControlsTimer();
  }

  void replayTenSeconds() {
    final currentPosition = videoController.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    videoController.seekTo(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
    showControlsTemporarily();
  }

  void forwardTenSeconds() {
    final currentPosition = videoController.value.position;
    final videoDuration = videoController.value.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);
    videoController.seekTo(
      newPosition > videoDuration ? videoDuration : newPosition,
    );
    showControlsTemporarily();
  }

  void togglePlayPause() {
    if (videoController.value.isPlaying) {
      videoController.pause();
    } else {
      videoController.play();
    }
    showControlsTemporarily();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

class FullscreenVideoPlayer extends StatelessWidget {
  final VideoPlayerController videoController;
  final String videoUrl;

  const FullscreenVideoPlayer({
    Key? key,
    required this.videoController,
    required this.videoUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      FullscreenVideoPlayerController(
        videoController: videoController,
        videoUrl: videoUrl,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: controller.toggleControls,
        child: Stack(
          children: [
            // Video Player
            Center(
              child: AspectRatio(
                aspectRatio: videoController.value.aspectRatio,
                child: VideoPlayer(videoController),
              ),
            ),

            // Controls Overlay
            AnimatedBuilder(
              animation: controller.controlsAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: controller.controlsAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: () => Get.back(),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.download,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    onPressed: () => controller.downloadVideo(
                                      context,
                                      controller.videoUrl,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                VideoProgressIndicator(
                                  videoController,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Color(0xFF6366F1),
                                    bufferedColor: Colors.white54,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.replay_10,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        onPressed: controller.replayTenSeconds,
                                      ),
                                    ),

                                    const SizedBox(width: 20),

                           
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1),
                                        borderRadius: BorderRadius.circular(35),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withOpacity(0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        iconSize: 40,
                                        icon: Icon(
                                          videoController.value.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        onPressed: controller.togglePlayPause,
                                      ),
                                    ),

                                    const SizedBox(width: 20),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.forward_10,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                        onPressed: controller.forwardTenSeconds,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                             
                                ValueListenableBuilder(
                                  valueListenable: videoController,
                                  builder: (
                                    context,
                                    VideoPlayerValue value,
                                    child,
                                  ) {
                                    final position = value.position;
                                    final duration = value.duration;

                                    return Text(
                                      "${controller.formatDuration(position)} / ${controller.formatDuration(duration)}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

