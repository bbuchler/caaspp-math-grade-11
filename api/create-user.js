module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");

  if (req.method === "OPTIONS") return res.status(200).end();
  if (req.method !== "POST") return res.status(405).json({ error: "Method not allowed" });

  const { name, password, role, username, email, contactEmail } = req.body;
  const userRole = ["student", "teacher"].includes(role) ? role : "student";
  const courseRole = userRole === "teacher" ? "teacher" : "student";
  const courseId = "caaspp-math-11";

  if (!name || !password) return res.status(400).json({ error: "Name and password are required." });
  if (password.length < 6) return res.status(400).json({ error: "Password must be at least 6 characters." });

  if (!username) return res.status(400).json({ error: "Username is required." });
  if (!/^[a-zA-Z0-9._-]+$/.test(username)) {
    return res.status(400).json({ error: "Username can only contain letters, numbers, dots, hyphens, and underscores." });
  }

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
      return res.status(403).json({ error: "Only teachers and admins can create accounts." });
    }

    const normalizedUsername = username.toLowerCase();
    const authEmail = `${normalizedUsername}@altus-caaspp-math.local`;

    const userMetadata = {
      full_name: name,
      role: userRole,
      username: normalizedUsername,
      contact_email: contactEmail || email || null,
      created_by: callerUser.id
    };

    const createRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`
      },
      body: JSON.stringify({
        email: authEmail,
        password,
        email_confirm: true,
        user_metadata: userMetadata
      })
    });
    const newUser = await createRes.json();
    if (!createRes.ok) {
      return res.status(400).json({ error: newUser.msg || newUser.message || newUser.error || "Failed to create user." });
    }

    const profileData = {
      id: newUser.id,
      full_name: name,
      email: authEmail,
      role: userRole,
      username: normalizedUsername,
      contact_email: contactEmail || email || null,
      created_by: callerUser.id,
      is_active: true
    };

    await fetch(`${SUPABASE_URL}/rest/v1/profiles`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        Prefer: "resolution=merge-duplicates,return=minimal"
      },
      body: JSON.stringify(profileData)
    });

    const enrollmentData = {
      course_id: courseId,
      user_id: newUser.id,
      role: courseRole,
      status: "active",
      created_by: callerUser.id
    };

    const enrollmentRes = await fetch(`${SUPABASE_URL}/rest/v1/course_enrollments`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: SERVICE_ROLE_KEY,
        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
        Prefer: "resolution=merge-duplicates,return=minimal"
      },
      body: JSON.stringify(enrollmentData)
    });

    if (!enrollmentRes.ok) {
      const text = await enrollmentRes.text();
      return res.status(400).json({ error: text || "Account created, but course enrollment failed." });
    }

    return res.status(200).json({
      success: true,
      userId: newUser.id,
      username: normalizedUsername,
      email: authEmail,
      contactEmail: contactEmail || email || null,
      role: userRole
    });
  } catch (err) {
    return res.status(500).json({ error: "Server error: " + (err.message || "Unknown") });
  }
};
