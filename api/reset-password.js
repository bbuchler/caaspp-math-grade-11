module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const { userId, newPassword } = req.body;
  if (!userId || !newPassword) return res.status(400).json({ error: "User ID and new password are required." });
  if (newPassword.length < 6) return res.status(400).json({ error: "Password must be at least 6 characters." });

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
    if (!["teacher", "staff", "admin"].includes(profiles[0]?.role)) {
      return res.status(403).json({ error: "Only teachers and admins can reset passwords." });
    }

    const enrollmentRes = await fetch(
      `${SUPABASE_URL}/rest/v1/course_enrollments?course_id=eq.caaspp-math-11&user_id=eq.${userId}&select=user_id`,
      { headers: { apikey: SERVICE_ROLE_KEY, Authorization: `Bearer ${SERVICE_ROLE_KEY}` } }
    );
    const enrollments = await enrollmentRes.json();
    if (!Array.isArray(enrollments) || !enrollments.length) {
      return res.status(403).json({ error: "This user is not enrolled in CAASPP Math." });
    }

    const updateRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${userId}`, {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`
      },
      body: JSON.stringify({ password: newPassword })
    });

    if (!updateRes.ok) {
      const err = await updateRes.json();
      return res.status(400).json({ error: err.msg || err.message || "Failed to reset password." });
    }

    return res.status(200).json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: "Server error: " + (err.message || "Unknown") });
  }
};
