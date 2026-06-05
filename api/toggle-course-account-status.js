module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const { userId, active } = req.body || {};
  const courseId = "caaspp-math-11";
  if (!userId) return res.status(400).json({ error: "User ID is required." });

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

    if (callerUser.id === userId && active === false) {
      return res.status(400).json({ error: "You cannot remove your own course access from this dashboard." });
    }

    const profileRes = await fetch(`${SUPABASE_URL}/rest/v1/profiles?id=eq.${callerUser.id}&select=role`, {
      headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` }
    });
    const profiles = await profileRes.json();
    const callerRole = profiles[0]?.role;
    if (!["teacher", "staff", "admin"].includes(callerRole)) {
      return res.status(403).json({ error: "Only teachers and admins can manage course accounts." });
    }

    const nextStatus = active ? "active" : "inactive";
    const enrollmentRes = await fetch(`${SUPABASE_URL}/rest/v1/course_enrollments?course_id=eq.${courseId}&user_id=eq.${userId}`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        Prefer: "return=minimal"
      },
      body: JSON.stringify({ status: nextStatus })
    });
    if (!enrollmentRes.ok) {
      const text = await enrollmentRes.text();
      return res.status(400).json({ error: text || "Could not update course enrollment." });
    }

    const sectionsRes = await fetch(`${SUPABASE_URL}/rest/v1/course_class_sections?course_id=eq.${courseId}&select=id`, {
      headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` }
    });
    const sections = await sectionsRes.json().catch(() => []);
    const sectionIds = Array.isArray(sections) ? sections.map((section) => section.id).filter(Boolean) : [];
    if (sectionIds.length) {
      const classIdFilter = sectionIds.join(",");
      await fetch(`${SUPABASE_URL}/rest/v1/course_class_teachers?teacher_id=eq.${userId}&class_id=in.(${classIdFilter})`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          Prefer: "return=minimal"
        },
        body: JSON.stringify({ status: nextStatus })
      });

      await fetch(`${SUPABASE_URL}/rest/v1/course_class_students?student_id=eq.${userId}&class_id=in.(${classIdFilter})`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          apikey: SERVICE_ROLE_KEY,
          Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
          Prefer: "return=minimal"
        },
        body: JSON.stringify({ status: active ? "active" : "inactive" })
      });
    }

    return res.status(200).json({ success: true, status: nextStatus });
  } catch (err) {
    return res.status(500).json({ error: "Server error: " + (err.message || "Unknown") });
  }
};
