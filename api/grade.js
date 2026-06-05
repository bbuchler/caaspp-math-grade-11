module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return res.status(500).json({ error: "Gemini API key not configured" });
  const model = process.env.GEMINI_MODEL || "gemini-2.5-flash-lite";

  const {
    question,
    questionText,
    studentAnswer,
    rubricId,
    lessonContext,
    maxPoints = 3
  } = req.body || {};

  if (!questionText || !studentAnswer) {
    return res.status(400).json({ error: "Missing questionText or studentAnswer" });
  }

  const points = Number(maxPoints) || 3;
  const safeQuestion = JSON.stringify(question || {}, null, 2).slice(0, 5000);
  const safeContext = JSON.stringify(lessonContext || {}, null, 2).slice(0, 9000);
  const expectedElements = Array.isArray(question?.expectedElements) ? question.expectedElements : [];
  const commonMisconceptions = Array.isArray(question?.commonMisconceptions) ? question.commonMisconceptions : [];

  const prompt = `You are grading an 11th grade CAASPP math short response.

LESSON CONTEXT:
${safeContext}

QUESTION DATA:
${safeQuestion}

QUESTION:
${questionText}

STUDENT ANSWER:
${studentAnswer}

RUBRIC ID:
${rubricId || "math-explanation-3"}

EXPECTED ELEMENTS:
${expectedElements.length ? expectedElements.map((item) => `- ${item}`).join("\n") : "- No separate expected elements provided."}

COMMON MISCONCEPTIONS TO WATCH FOR:
${commonMisconceptions.length ? commonMisconceptions.map((item) => `- ${item}`).join("\n") : "- No separate misconceptions provided."}

GRADING RULES:
- Grade math reasoning, not spelling or polished writing.
- Full credit (${points}/${points}): student gives a correct mathematical idea and enough explanation to show why it works.
- For factual-short-2, full credit means the student communicates the expected idea in any reasonable wording; do not require the exact answer key phrase.
- For factual-short-2, partial credit means the student has an important correct piece but misses a meaningful detail such as a negative sign, unit, or vocabulary connection.
- Do not give credit merely because the response contains keywords. The sentence has to mean the correct thing.
- Partial credit: student is on the right track but misses a key step, uses weak vocabulary, or gives an incomplete explanation.
- Low credit: student attempts the prompt but shows a major misconception.
- Zero: blank, off-topic, or no meaningful math reasoning.
- If the question is error analysis, look for the exact mistake and the corrected idea.
- If the response appears copied, unrelated, or too unclear to judge, set needsTeacherReview to true.

FEEDBACK RULES:
- Give one clear strength and one next step.
- Use student-friendly language.
- Keep feedback to 1-3 sentences.

Respond in exactly this JSON shape, with no markdown:
{
  "score": 0,
  "maxScore": ${points},
  "feedback": "string",
  "correct": false,
  "confidence": 0.0,
  "needsTeacherReview": false
}`;

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: controller.signal,
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.2,
            maxOutputTokens: 800,
            thinkingConfig: { thinkingBudget: 0 }
          }
        })
      }
    );

    clearTimeout(timeout);

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      console.error("Gemini API error:", geminiRes.status, errText.slice(0, 500));
      if (geminiRes.status === 429) {
        return res.status(429).json({ error: "AI grading quota was reached. Try again in a minute, or ask your teacher to review this response." });
      }
      return res.status(502).json({ error: "AI grading is temporarily unavailable." });
    }

    const geminiData = await geminiRes.json();
    const parts = geminiData.candidates?.[0]?.content?.parts || [];
    const textPart = parts.find((part) => part.text !== undefined);
    const rawText = textPart?.text || "";
    const cleaned = rawText.replace(/```json\s*/g, "").replace(/```\s*/g, "").trim();
    const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
    const parsed = JSON.parse(jsonMatch ? jsonMatch[0] : cleaned);

    const score = Math.max(0, Math.min(points, Math.round(Number(parsed.score) || 0)));
    const confidence = Math.max(0, Math.min(1, Number(parsed.confidence) || 0));

    return res.status(200).json({
      score,
      maxScore: points,
      feedback: parsed.feedback || "Reviewed.",
      correct: score >= points * 0.7,
      confidence,
      needsTeacherReview: Boolean(parsed.needsTeacherReview || confidence < 0.65)
    });
  } catch (err) {
    const message = err.name === "AbortError" ? "AI grading timed out." : "AI grading failed.";
    console.error("Grading error:", err);
    return res.status(500).json({ error: message });
  }
};
