import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_genrater_gemini_integration/controllers/chatScreenCont.dart';
import 'package:video_genrater_gemini_integration/utils/modeOption.dart';

class ModeSelector extends StatelessWidget {
  final ChatScreenController controller;

  const ModeSelector({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10),
    //  padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Generation Mode",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ModeOption(
                  controller: controller,
                  title: "Text Only",
                  icon: Icons.text_fields,
                  value: 0,
                  description: "Generate from text",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModeOption(
                  controller: controller,
                  title: "Generate Image",
                  icon: Icons.auto_awesome,
                  value: 1,
                  description: "AI creates image",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ModeOption(
                  controller: controller,
                  title: "Upload Image",
                  icon: Icons.upload,
                  value: 2,
                  description: "Use your image",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
