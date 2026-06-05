module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const { name, location, term } = req.body || {};
  const courseId = "caaspp-math-11";
  if (!name || !String(name).trim()) return res.status(400).json({ error: "Class name is required." });

  const SUPABASE_URL = process.env.SUPABASE_URL || "https://vulzhiifgxrimpquhsvg.supabase.co";
  const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!SERVICE_ROLE_KEY) {
    return res.status(500).json({ error: "Server configuration error: missing service role key." });
  }

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Not authenticated." });
  }

  try {
    const callerToken = authHeader.replace("Bearer ", "");
    const callerRes = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { Authorization: `Bearer ${callerToken}`, apikey: SERVICE_ROLE_KEY }
    });
    const callerUser = await callerRes.json();
    if (!callerUser || !callerUser.id) return res.status(401).json({ error: "Invalid session." });

    const profileRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${callerUser.id}&select=role`, {
      headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` }
    });
    const profiles = await profileRes.json();
    const callerRole = profiles[0]?.role;
    if (!["teacher", "staff", "admin"].includes(callerRole)) {
      return res.status(403).json({ error: "Only teachers and admins can create classes." });
    }

    const sectionRes = await fetch(`${SUPABASE_URL}/rest/v1/course_class_sections`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        Prefer: "resolution=merge-duplicates,return=representation"
      },
      body: JSON.stringify({
        course_id: courseId,
        name: String(name).trim(),
        location: location ? String(location).trim() : null,
        term: term ? String(term).trim() : null,
        status: "active",
        created_by: callerUser.id
      })
    });
    const sections = await sectionRes.json();
    if (!sectionRes.ok || !Array.isArray(sections) || !sections.length) {
      return res.status(400).json({ error: sections?.message || sections?.details || "Could not create class." });
    }

    const section = sections[0];
    const teacherRes = await fetch(`${SUPABASE_URL}/rest/v1/course_class_teachers`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        Prefer: "resolution=merge-duplicates,return=minimal"
      },
      body: JSON.stringify({
        class_id: section.id,
        teacher_id: callerUser.id,
        role: callerRole === "admin" ? "admin" : "teacher",
        status: "active",
        created_by: callerUser.id
      })
    });
    if (!teacherRes.ok) {
      const text = await teacherRes.text();
      return res.status(400).json({ error: text || "Class created, but teacher assignment failed." });
    }

    return res.status(200).json({ success: true, section });
  } catch (err) {
    return res.status(500).json({ error: "Server error: " + (err.message || "Unknown") });
  }
};
