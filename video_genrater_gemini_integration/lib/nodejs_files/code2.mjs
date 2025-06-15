
import express from 'express';
import { GoogleGenAI } from "@google/genai";
import { createWriteStream } from "fs";
import { Readable } from "stream";
import cors from 'cors';
import fetch from 'node-fetch';

const app = express();
app.use(cors());
app.use(express.json());

const API_KEY = "AIzaSyApI2seQi8d2cv-WoF9evYDKebJ9Gq94F8";
const ai = new GoogleGenAI({ apiKey: API_KEY });

app.post('/generate-video-from-image', async (req, res) => {
  const { prompt, imagePrompt } = req.body;
  
  if (!prompt?.trim()) {
    return res.status(400).json({ error: "Video prompt required" });
  }
  
  if (!imagePrompt?.trim()) {
    return res.status(400).json({ error: "Image prompt required" });
  }

  try {
    console.log("Generating image...");
    const imageResponse = await ai.models.generateImages({
      model: "imagen-3.0-generate-002",
      prompt: imagePrompt,
      config: {
        numberOfImages: 1,
      },
    });

    if (!imageResponse.generatedImages?.length) {
      return res.status(500).json({ error: "Failed to generate image" });
    }

    const imageBytes = imageResponse.generatedImages[0].image.imageBytes;
    console.log("Image generated successfully");

    console.log("Using generated image for video creation");

    console.log("Generating video from image...");
    let operation = await ai.models.generateVideos({
      model: "veo-2.0-generate-001",
      prompt: prompt,
      image: {
        imageBytes: imageBytes, 
        mimeType: "image/png",
      },
      config: {
        aspectRatio: "16:9",
        numberOfVideos: 1,
      },
    });

    while (!operation.done) {
      console.log("Video generation in progress...");
      await new Promise((resolve) => setTimeout(resolve, 10000));
      operation = await ai.operations.getVideosOperation({ operation });
    }

    if (operation.response?.generatedVideos?.length) {
      const videoUrl = operation.response.generatedVideos[0].video?.uri;
      console.log("Video generated successfully");
      return res.json({ 
        videoUrl: `${videoUrl}&key=${API_KEY}`,
        message: "Video generated successfully from image"
      });
    }

    res.status(500).json({ error: "No video generated" });
  } catch (err) {
    console.error("Error:", err);
    res.status(500).json({ error: err.message });
  }
});

// Alternative endpoint for text-only video generation (your existing functionality)
app.post('/generate-video', async (req, res) => {
  const userPrompt = req.body.prompt;

  if (!userPrompt?.trim()) return res.status(400).json({ error: "Prompt required" });

  try {
    let operation = await ai.models.generateVideos({
      model: "veo-2.0-generate-001",
      prompt: userPrompt,
      config: {
        personGeneration: "dont_allow",
        aspectRatio: "16:9",
      },
    });

    while (!operation.done) {
      await new Promise((resolve) => setTimeout(resolve, 10000));
      operation = await ai.operations.getVideosOperation({ operation });
    }

    if (operation.response?.generatedVideos?.length) {
      const videoUrl = operation.response.generatedVideos[0].video?.uri;
      return res.json({ videoUrl: `${videoUrl}&key=${API_KEY}` });
    }

    res.status(500).json({ error: "No video generated" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Endpoint to upload and use existing image for video generation
app.post('/generate-video-from-uploaded-image', express.raw({ type: 'image/*', limit: '10mb' }), async (req, res) => {
  const { prompt } = req.query;
  
  if (!prompt?.trim()) {
    return res.status(400).json({ error: "Video prompt required" });
  }
  
  if (!req.body || req.body.length === 0) {
    return res.status(400).json({ error: "Image data required" });
  }

  try {
    console.log("Generating video from uploaded image...");
    
    // Convert binary data to base64 string
    const imageBase64 = req.body.toString('base64');
    console.log("Image converted to base64, length:", imageBase64.length);
    
    let operation = await ai.models.generateVideos({
      model: "veo-2.0-generate-001",
      prompt: prompt,
      image: {
        imageBytes: imageBase64,
        mimeType: req.get('Content-Type') || "image/png",
      },
      config: {
        aspectRatio: "16:9",
        numberOfVideos: 1,
      },
    });

    while (!operation.done) {
      console.log("Video generation in progress...");
      await new Promise((resolve) => setTimeout(resolve, 10000));
      operation = await ai.operations.getVideosOperation({ operation });
    }

    if (operation.response?.generatedVideos?.length) {
      const videoUrl = operation.response.generatedVideos[0].video?.uri;
      console.log("Video generated successfully");
      return res.json({ 
        videoUrl: `${videoUrl}&key=${API_KEY}`,
        message: "Video generated successfully from uploaded image"
      });
    }

    res.status(500).json({ error: "No video generated" });
  } catch (err) {
    console.error("Error:", err);
    res.status(500).json({ error: err.message });
  }
});

app.listen(3000, () => {
  console.log("✅ Server running on http://localhost:3000");
  console.log("📋 Available endpoints:");
  console.log("  POST /generate-video - Generate video from text prompt");
  console.log("  POST /generate-video-from-image - Generate image first, then video");
  console.log("  POST /generate-video-from-uploaded-image - Generate video from uploaded image");
});