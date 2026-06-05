module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) return res.status(500).json({ error: "Gemini API key not configured" });
  const model = process.env.GEMINI_MODEL || "gemini-2.5-flash-lite";

  const { messages, lessonContext } = req.body || {};
  if (!Array.isArray(messages) || messages.length === 0) {
    return res.status(400).json({ error: "Missing messages array" });
  }

  const safeContext = JSON.stringify(lessonContext || {}, null, 2).slice(0, 12000);
  const systemPrompt = `You are the Study Buddy for an 11th grade CAASPP Math Success Academy course.

Use the current lesson context below to answer questions about what the student is seeing on the page.

CURRENT LESSON CONTEXT:
${safeContext}

ROLE:
- Help students understand the current math idea.
- Give a short hint first when the student is working on an active graded problem.
- If the student is stuck, explain the concept clearly using a similar example with different numbers.
- Help students revise reasoning, identify a mistake, and understand vocabulary like coefficient, inverse operation, inequality, slope, intercept, function, input, and output.

BOUNDARIES:
- Do not reveal final answers for active graded checks.
- Do not write the student's constructed response for them.
- Do not discuss unrelated topics.
- If a student asks for the answer, ask one guiding question or solve a similar problem instead.

TONE:
- Friendly, direct, and appropriate for high school students.
- Keep most responses to 2-5 sentences.
- Use simple math formatting that is easy to read in plain text.`;

  const contents = messages.map((msg) => ({
    role: msg.role === "assistant" || msg.role === "model" ? "model" : "user",
    parts: [{ text: String(msg.content || "") }]
  }));

  try {
    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          system_instruction: { parts: [{ text: systemPrompt }] },
          contents,
          generationConfig: {
            temperature: 0.5,
            maxOutputTokens: 900,
            thinkingConfig: { thinkingBudget: 0 }
          }
        })
      }
    );

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      console.error("Gemini API error:", geminiRes.status, errText.slice(0, 500));
      if (geminiRes.status === 429) {
        return res.status(429).json({ error: "Study Buddy quota was reached. Try again in a minute." });
      }
      return res.status(502).json({ error: "Study Buddy is temporarily unavailable." });
    }

    const geminiData = await geminiRes.json();
    const parts = geminiData.candidates?.[0]?.content?.parts || [];
    const textPart = parts.find((part) => part.text !== undefined);
    const reply = textPart?.text || "Try asking that another way.";

    return res.status(200).json({ reply });
  } catch (err) {
    console.error("Chat error:", err);
    return res.status(500).json({ error: "Study Buddy failed." });
  }
};
