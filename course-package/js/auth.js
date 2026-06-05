(function () {
  const STUDENT_DOMAIN = "@altus-drivers-ed.local";

  async function getSession() {
    const { data } = await supabase.auth.getSession();
    return data?.session || null;
  }

  async function getProfile() {
    const session = await getSession();
    if (!session) return null;
    const { data, error } = await supabase
      .from("profiles")
      .select("*")
      .eq("id", session.user.id)
      .single();
    if (error) return null;
    return data;
  }

  async function signIn(login, password) {
    const email = login.includes("@") ? login : `${login}${STUDENT_DOMAIN}`;
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
    return data;
  }

  async function signOut() {
    await supabase.auth.signOut();
    window.location.href = "index.html";
  }

  async function requireRole(roles) {
    const profile = await getProfile();
    if (!profile) {
      window.location.href = "index.html";
      return null;
    }
    if (roles && !roles.includes(profile.role)) {
      window.location.href = profile.role === "student" ? "student-dashboard.html" : "admin-dashboard.html";
      return null;
    }
    return profile;
  }

  function routeFor(profile) {
    if (["admin", "staff", "teacher"].includes(profile.role)) return "teacher-dashboard.html";
    return "student-dashboard.html";
  }

  window.CAASPPAuth = {
    getSession,
    getProfile,
    signIn,
    signOut,
    requireRole,
    routeFor
  };
})();
