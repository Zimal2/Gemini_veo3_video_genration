import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_genrater_gemini_integration/controllers/chatScreenCont.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_genrater_gemini_integration/controllers/chatScreenCont.dart';
import 'package:video_player/video_player.dart';

class ImageSection extends StatelessWidget {
  final ChatScreenController controller;

  const ImageSection({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedMode.value == 1) {
        return ImagePromptField(controller: controller);
      } else if (controller.selectedMode.value == 2) {
        return ImageUploadSection(controller: controller);
      }
      return const SizedBox();
    });
  }
}

// Image Prompt Field Widget
class ImagePromptField extends StatelessWidget {
  final ChatScreenController controller;

  const ImagePromptField({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedMode.value == 1) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            controller: controller.imagePromptController,
            decoration: const InputDecoration(
              hintText: 'Describe the image you want to generate...',
              labelText: 'Image Prompt',
              prefixIcon: Icon(Icons.palette, color: Color(0xFF6366F1)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
            ),
            maxLines: 2,
          ),
        );
      }
      return const SizedBox();
    });
  }
}

// Image Upload Section Widget - Improved for better scrolling
class ImageUploadSection extends StatelessWidget {
  final ChatScreenController controller;

  const ImageUploadSection({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Upload button at the top
          ElevatedButton.icon(
            onPressed: controller.pickImage,
            icon: const Icon(Icons.add_photo_alternate),
            label: Obx(() => Text(controller.selectedImageButtonText)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Image preview with constrained height
          Obx(() {
            if (controller.hasSelectedImage) {
              return Container(
                constraints: const BoxConstraints(
                  maxHeight: 300, // Limit height to prevent overflow
                  minHeight: 150,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Image display
                      kIsWeb && controller.selectedImageBytes.value != null
                          ? Image.memory(
                              controller.selectedImageBytes.value!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : !kIsWeb && controller.selectedImage.value != null
                              ? Image.file(
                                  controller.selectedImage.value!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey[600],
                                  ),
                                ),
                      
                      // Overlay with change button
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: controller.pickImage,
                            tooltip: 'Change Image',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }
}

// Selected Image Preview Widget - Standalone if needed
class SelectedImagePreview extends StatelessWidget {
  final ChatScreenController controller;

  const SelectedImagePreview({Key? key, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: kIsWeb && controller.selectedImageBytes.value != null
            ? Image.memory(
                controller.selectedImageBytes.value!,
                fit: BoxFit.cover,
              )
            : !kIsWeb && controller.selectedImage.value != null
                ? Image.file(controller.selectedImage.value!, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey[300],
                    child: Icon(Icons.image, size: 50, color: Colors.grey[600]),
                  ),
      ),
    );
  }
}
// Video Player Widget with better error handling and state management
class CustomVideoPlayer extends StatelessWidget {
  final ChatScreenController controller;

  const CustomVideoPlayer({Key? key, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading state while video is initializing
      if (controller.isVideoInitializing.value) {
        return Container(
          margin: const EdgeInsets.all(20),
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
                SizedBox(height: 16),
                Text(
                  'Initializing video...',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }

      // Check if video is properly initialized
      if (!controller.isVideoInitialized) {
        // Show placeholder if we have a URL but video isn't initialized yet
        if (controller.videoUrl.value.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.all(20),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.video_file, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Video ready, initializing player...',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed:
                        () => controller.initializeVideo(
                          controller.videoUrl.value,
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      }

      // Display the video player
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
            Obx(() => VideoPlayerControls(controller: controller)),
          ],
        ),
      );
    });
  }
}

// Video Player Controls Widget
class VideoPlayerControls extends StatelessWidget {
  final ChatScreenController controller;

  const VideoPlayerControls({Key? key, required this.controller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (controller.videoController.value == null) {
      return const SizedBox();
    }

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar
            VideoProgressIndicator(
              controller.videoController.value!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFF6366F1),
                bufferedColor: Colors.white54,
                backgroundColor: Colors.white24,
              ),
            ),

            const SizedBox(height: 12),

            // Control Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Play/Pause Button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      controller.isVideoPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: controller.toggleVideoPlayPause,
                  ),
                ),

                // Fullscreen Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: controller.openFullscreenVideo,
                  ),
                ),

                // Download Button
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
                    onPressed:
                        () => controller.downloadVideo(
                          controller.videoUrl.value,
                          context: context,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ValueListenableBuilder(
              valueListenable: controller.videoController.value!,
              builder: (context, VideoPlayerValue value, child) {
                final position = value.position;
                final duration = value.duration;

                return Text(
                  "${_formatDuration(position)} / ${_formatDuration(duration)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
