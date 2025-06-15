import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_genrater_gemini_integration/controllers/chatScreenCont.dart';

class BottomInputSection extends StatelessWidget {
  final ChatScreenController controller;

  const BottomInputSection({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
        return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.promptController,
                decoration: const InputDecoration(
                  hintText: 'Describe the video you want to create...',
                  prefixIcon: Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF6366F1),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF6366F1), width: 2),
                  ),
                ),
                maxLines: null,
              ),
            ),
            const SizedBox(width: 16),
            Obx(
              () => Container(
                decoration: BoxDecoration(
                  gradient:
                      controller.isLoading.value
                          ? LinearGradient(
                            colors: [
                              Colors.grey.shade400,
                              Colors.grey.shade500,
                            ],
                          )
                          : const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (controller.isLoading.value
                              ? Colors.grey
                              : const Color(0xFF6366F1))
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap:
                        controller.isLoading.value
                            ? null
                            : controller.generateVideo,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child:
                          controller.isLoading.value
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
 
  }
}

class GenerateButton extends StatelessWidget {
  final ChatScreenController controller;

  const GenerateButton({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      decoration: BoxDecoration(
        gradient: controller.isLoading.value 
            ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500])
            : const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (controller.isLoading.value ? Colors.grey : const Color(0xFF6366F1)).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: controller.isLoading.value ? null : controller.generateVideo,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: controller.isLoading.value 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
          ),
        ),
      ),
    ));
  }
}