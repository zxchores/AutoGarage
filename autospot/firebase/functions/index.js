/**
 * Cloud Function template: photo in Storage -> Vision LLM -> catalog XP.
 * Deploy only after creating a Firebase project and setting GEMINI_API_KEY.
 */
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

admin.initializeApp();
const geminiKey = defineSecret("GEMINI_API_KEY");

const VISION_PROMPT = `You are an automotive identification engine.
Return STRICT JSON only with keys:
is_car, make, model, generation, year_from, year_to, body_type, color,
confidence (low|medium|high), condition (excellent|good|damaged|restoration|corrosion),
tuning {bodykit,wheels,spoiler,vinyl,exhaust,lowered,details[]},
photo_quality (poor|average|good|excellent), visible_license_plate, notes.
Never transcribe license plates or faces.`;

exports.identifyCar = onCall({ secrets: [geminiKey], region: "europe-west1" }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in first");
  }
  const { imageBase64 } = request.data || {};
  if (!imageBase64) {
    throw new HttpsError("invalid-argument", "imageBase64 required");
  }
  const url =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=" +
    geminiKey.value();
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            { text: VISION_PROMPT },
            { inline_data: { mime_type: "image/jpeg", data: imageBase64 } },
          ],
        },
      ],
      generationConfig: { temperature: 0.2, responseMimeType: "application/json" },
    }),
  });
  if (!response.ok) {
    throw new HttpsError("internal", "Vision provider failed");
  }
  const payload = await response.json();
  const text = payload.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new HttpsError("internal", "Empty model response");
  return JSON.parse(text);
});
