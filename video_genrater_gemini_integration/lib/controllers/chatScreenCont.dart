import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_genrater_gemini_integration/controllers/videoPlayCont.dart';
import 'dart:convert';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:html' as html;

class ChatScreenController extends GetxController
    with GetTickerProviderStateMixin {
  final TextEditingController promptController = TextEditingController();
  final TextEditingController imagePromptController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final ImagePicker _picker = ImagePicker();

  final RxBool isLoading = false.obs;
  final RxString videoUrl = ''.obs;
  final Rx<VideoPlayerController?> videoController = Rx<VideoPlayerController?>(
    null,
  );
  final Rx<File?> selectedImage = Rx<File?>(null);
  final Rx<Uint8List?> selectedImageBytes = Rx<Uint8List?>(null);
  final RxInt selectedMode = 0.obs;

  final RxBool isVideoInitializing = false.obs;
  final RxBool videoInitialized = false.obs;

  late AnimationController pulseController;
  late Animation<double> pulseAnimation;

  @override
  void onInit() {
    super.onInit();
    _initializeAnimations();
  }

  @override
  void onClose() {
    promptController.dispose();
    imagePromptController.dispose();
    videoController.value?.dispose();
    pulseController.dispose();
      scrollController.dispose();
    super.onClose();
  }

  void _initializeAnimations() {
    pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: pulseController, curve: Curves.easeInOut),
    );
    pulseController.repeat(reverse: true);
  }

  Future<void> downloadVideo(String videoUrl, {required BuildContext context}) async {
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
  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          selectedImageBytes.value = bytes;
          selectedImage.value = null;
        } else {
          selectedImage.value = File(image.path);
          selectedImageBytes.value = null;
        }
        
        // Auto-scroll to show the uploaded image in mode 2
        if (selectedMode.value == 2) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _scrollToContent();
          });
        }
      }
    } catch (e) {
      showSnackBar("Failed to pick image: $e", isError: true);
    }
  }
  
  void showSnackBar(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? 'Error' : 'Success',
      message,
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 12,
      margin: const EdgeInsets.all(16),
    );
  }
 Future<void> generateVideo() async {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      showSnackBar("Please enter a video prompt", isError: true);
      return;
    }

    if (selectedMode.value == 1 && imagePromptController.text.trim().isEmpty) {
      showSnackBar("Please enter an image prompt", isError: true);
      return;
    }

    if (selectedMode.value == 2 &&
        selectedImage.value == null &&
        selectedImageBytes.value == null) {
      showSnackBar("Please upload an image", isError: true);
      return;
    }

    isLoading.value = true;
    isVideoInitializing.value = false;
    videoInitialized.value = false;
    videoUrl.value = '';

    // Auto-scroll to show loading state
    _scrollToContent();

    if (videoController.value != null) {
      await videoController.value!.dispose();
      videoController.value = null;
    }

    try {
      http.Response response;

      switch (selectedMode.value) {
        case 0:
          response = await generateTextToVideo(prompt);
          break;
        case 1:
          response = await generateImageToVideo(
            prompt,
            imagePromptController.text.trim(),
          );
          break;
        case 2:
          if (kIsWeb && selectedImageBytes.value != null) {
            response = await generateUploadedImageToVideoWeb(
              prompt,
              selectedImageBytes.value!,
            );
          } else if (!kIsWeb && selectedImage.value != null) {
            response = await generateUploadedImageToVideo(
              prompt,
              selectedImage.value!,
            );
          } else {
            throw Exception("No image selected");
          }
          break;
        default:
          throw Exception("Invalid mode selected");
      }

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newVideoUrl =
            data['videoUrl'] ?? data['url'] ?? data['video_url'];

        if (newVideoUrl != null && newVideoUrl.isNotEmpty) {
          print("Setting video URL: $newVideoUrl");
          videoUrl.value = newVideoUrl;

          // Initialize video with better error handling
          await initializeVideo(newVideoUrl);
          
          // Auto-scroll to show the generated video
          _scrollToContent();
        } else {
          throw Exception('No video URL received from server');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          errorData['error'] ?? 'Server returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      print("Error generating video: $e");
      showSnackBar("Failed to generate video: $e", isError: true);
      videoUrl.value = '';
      videoInitialized.value = false;
    } finally {
      isLoading.value = false;
      isVideoInitializing.value = false;
    }
  }
    void _scrollToContent() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent * 0.5, // Scroll to middle-bottom
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  // Method to scroll to video when it's ready
  void scrollToVideo() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }
  Future<void> initializeVideo(String url) async {
    try {
      isVideoInitializing.value = true;
      print("Initializing video with URL: $url");

      final newController = VideoPlayerController.network(url);
      videoController.value = newController;

      newController.addListener(() {
        if (newController.value.hasError) {
          print("Video player error: ${newController.value.errorDescription}");
          showSnackBar(
            "Video player error: ${newController.value.errorDescription}",
            isError: true,
          );
        }
      });

      await newController.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video initialization timeout');
        },
      );

      if (newController.value.isInitialized) {
        videoInitialized.value = true;
        print("Video initialized successfully");

        await newController.play();
        showSnackBar("Video generated successfully!");
      } else {
        throw Exception('Video failed to initialize');
      }
    } catch (e) {
      print("Video initialization error: $e");
      showSnackBar("Failed to initialize video: $e", isError: true);
      videoInitialized.value = false;
      videoUrl.value = '';
    } finally {
      isVideoInitializing.value = false;
    }
  }

  void openFullscreenVideo() {
    if (videoController.value != null &&
        videoController.value!.value.isInitialized) {
      Get.to(
        () => FullscreenVideoPlayer(
          videoController: videoController.value!,
          videoUrl: videoUrl.value,
        ),
      );
    }
  }

  Future<http.Response> generateTextToVideo(String prompt) async {
    return await http.post(
      Uri.parse('http://localhost:3000/generate-video'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );
  }

  Future<http.Response> generateImageToVideo(
    String prompt,
    String imagePrompt,
  ) async {
    return await http.post(
      Uri.parse('http://localhost:3000/generate-video-from-image'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt, 'imagePrompt': imagePrompt}),
    );
  }

  Future<http.Response> generateUploadedImageToVideo(
    String prompt,
    File imageFile,
  ) async {
    final imageBytes = await imageFile.readAsBytes();
    final uri = Uri.parse(
      'http://localhost:3000/generate-video-from-uploaded-image',
    ).replace(queryParameters: {'prompt': prompt});

    return await http.post(
      uri,
      headers: {'Content-Type': 'image/png'},
      body: imageBytes,
    );
  }

  Future<http.Response> generateUploadedImageToVideoWeb(
    String prompt,
    Uint8List imageBytes,
  ) async {
    final uri = Uri.parse(
      'http://localhost:3000/generate-video-from-uploaded-image',
    ).replace(queryParameters: {'prompt': prompt});

    return await http.post(
      uri,
      headers: {'Content-Type': 'image/png'},
      body: imageBytes,
    );
  }

  void setSelectedMode(int mode) {
    selectedMode.value = mode;
  }

  void toggleVideoPlayPause() {
    if (videoController.value != null) {
      if (videoController.value!.value.isPlaying) {
        videoController.value!.pause();
      } else {
        videoController.value!.play();
      }
      update();
    }
  }

  bool get isVideoInitialized =>
      videoInitialized.value &&
      videoController.value != null &&
      videoController.value!.value.isInitialized;

  bool get isVideoPlaying =>
      videoController.value != null && videoController.value!.value.isPlaying;

  double get videoAspectRatio =>
      videoController.value?.value.aspectRatio ?? 16 / 9;

  bool get hasSelectedImage =>
      selectedImage.value != null || selectedImageBytes.value != null;

  String get selectedImageButtonText =>
      hasSelectedImage ? "Change Image" : "Upload Image";
}

