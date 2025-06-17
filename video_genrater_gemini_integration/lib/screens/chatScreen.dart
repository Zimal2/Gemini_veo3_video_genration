import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_genrater_gemini_integration/controllers/chatScreenCont.dart';
import 'package:video_genrater_gemini_integration/utils/buttons.dart';
import 'package:video_genrater_gemini_integration/utils/customAppbar.dart';
import 'package:video_genrater_gemini_integration/utils/customModuleSel.dart';
import 'package:video_genrater_gemini_integration/utils/imageWidgets.dart';
import 'package:video_genrater_gemini_integration/utils/videoWidget.dart';
import 'package:video_player/video_player.dart';
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatScreenController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(),
      body: Column(
        children: [
          ModeSelector(controller: controller),          
          Expanded(
            child: SingleChildScrollView(
              controller: controller.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  ImageSection(controller: controller),
                  
                  Obx(() {
                    if (controller.isLoading.value) {
                      return LoadingState(controller: controller);
                    }
                    return const SizedBox();
                  }),
                  
                  Obx(() {
                    if (controller.videoUrl.value.isNotEmpty) {
                      return _buildVideoPlayer(controller, context);
                    }
                    return const SizedBox();
                  }),
                                    const SizedBox(height: 100),
                ],
              ),
            ),
          ),
                    BottomInputSection(controller: controller),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(
    ChatScreenController controller,
    BuildContext context,
  ) {
    return Obx(() {
      if (!controller.isVideoInitialized) {
        return const SizedBox();
      }

      return Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: controller.videoAspectRatio,
                child: VideoPlayer(controller.videoController.value!),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Obx(
                        () => Icon(
                          controller.isVideoPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onPressed: controller.toggleVideoPlayPause,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: controller.openFullscreenVideo,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.download,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => controller.downloadVideo(
                        controller.videoUrl.value,
                        context: context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}