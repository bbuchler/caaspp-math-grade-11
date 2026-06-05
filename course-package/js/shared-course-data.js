(function () {
  const COURSE_ID = "caaspp-math-11";

  function hasSupabase() {
    return Boolean(window.supabase && typeof window.supabase.from === "function");
  }

  async function getSession() {
    if (!hasSupabase()) return null;
    const { data } = await window.supabase.auth.getSession();
    return data?.session || null;
  }

  async function getProfile(userId) {
    if (!hasSupabase() || !userId) return null;
    const { data, error } = await window.supabase
      .from("profiles")
      .select("id,role,full_name,username,email")
      .eq("id", userId)
      .single();
    if (error) return null;
    return data;
  }

  async function isStudentSession(session) {
    const profile = await getProfile(session?.user?.id);
    return profile?.role === "student";
  }

  function lessonNumberFromId(lessonId) {
    return Number(String(lessonId || "1").replace(/^0+/, "")) || 1;
  }

  function conceptTags(question) {
    const text = `${question.prompt || ""} ${question.sectionTitle || ""}`.toLowerCase();
    const tags = [];
    if (text.includes("coefficient")) tags.push("coefficient");
    if (text.includes("inverse") || text.includes("undo")) tags.push("inverse_operations");
    if (text.includes("check") || text.includes("substitut")) tags.push("checking_solutions");
    if (text.includes("equation") || text.includes("solve")) tags.push("linear_equations");
    return tags.length ? tags : ["lesson_1"];
  }

  async function saveQuestionResponse(payload) {
    const session = await getSession();
    if (!session) return { mode: "local", saved: false };
    if (!(await isStudentSession(session))) {
      return { mode: "supabase", saved: false, skipped: "not_student" };
    }

    const question = payload.question || {};
    const result = payload.result || {};
    const lessonNumber = lessonNumberFromId(payload.lessonId);
    const maxScore = Number(result.maxScore ?? 1);
    const score = Number(result.score || 0);
    const gradingMethod = question.grading === "ai_rubric"
      ? "ai_rubric"
      : question.grading === "teacher_override"
        ? "teacher_override"
        : "deterministic";

    const row = {
      course_id: COURSE_ID,
      student_id: session.user.id,
      lesson_number: lessonNumber,
      section_id: question.sectionId || "",
      section_title: question.sectionTitle || "",
      question_id: question.id,
      question_type: question.type || "short_answer",
      prompt: question.prompt || "",
      answer: String(payload.answer ?? ""),
      score,
      max_score: maxScore,
      feedback: result.feedback || "",
      grading_method: gradingMethod,
      ai_confidence: result.confidence ?? null,
      needs_teacher_review: Boolean(result.needsTeacherReview),
      concept_tags: conceptTags(question),
      misconception_tags: []
    };

    await ensureEnrollment(session.user.id, "student");

    const { error } = await window.supabase
      .from("course_question_responses")
      .upsert(row, { onConflict: "course_id,student_id,lesson_number,question_id" });

    if (error) return { mode: "supabase", saved: false, error };
    await updateLessonAttempt(session.user.id, lessonNumber);
    return { mode: "supabase", saved: true };
  }

  async function ensureEnrollment(userId, role) {
    if (!userId) return;
    await window.supabase
      .from("course_enrollments")
      .upsert({
        course_id: COURSE_ID,
        user_id: userId,
        role,
        status: "active",
        created_by: userId
      }, { onConflict: "course_id,user_id" });
  }

  async function loadCourseStudents() {
    const session = await getSession();
    if (!session) return null;
    const { data, error } = await window.supabase
      .from("course_enrollments")
      .select("user_id,role,status,profiles:user_id(id,full_name,username,email)")
      .eq("course_id", COURSE_ID)
      .eq("role", "student")
      .eq("status", "active");
    if (error) return null;
    return (data || []).map((row) => ({
      id: row.user_id,
      full_name: row.profiles?.full_name || "",
      username: row.profiles?.username || "",
      email: row.profiles?.email || "",
      status: row.status
    })).sort((a, b) => a.full_name.localeCompare(b.full_name));
  }

  async function loadCourseTeachers() {
    const session = await getSession();
    if (!session) return null;
    const { data, error } = await window.supabase
      .from("course_enrollments")
      .select("user_id,role,status,profiles:user_id(id,full_name,username,email,role)")
      .eq("course_id", COURSE_ID)
      .in("role", ["teacher", "staff", "admin"])
      .order("role");
    if (error) return null;
    return (data || []).map((row) => ({
      id: row.user_id,
      courseRole: row.role,
      status: row.status,
      full_name: row.profiles?.full_name || "",
      username: row.profiles?.username || "",
      email: row.profiles?.email || "",
      role: row.profiles?.role || row.role
    }));
  }

  async function enrollUser(userId, role = "student") {
    const session = await getSession();
    if (!session || !userId) return { saved: false };
    const { error } = await window.supabase
      .from("course_enrollments")
      .upsert({
        course_id: COURSE_ID,
        user_id: userId,
        role,
        status: "active",
        created_by: session.user.id
      }, { onConflict: "course_id,user_id" });
    return { saved: !error, error };
  }

  async function updateLessonAttempt(studentId, lessonNumber, statusOverride = null) {
    const { data, error } = await window.supabase
      .from("course_question_responses")
      .select("score,max_score,needs_teacher_review,section_id")
      .eq("course_id", COURSE_ID)
      .eq("student_id", studentId)
      .eq("lesson_number", lessonNumber);

    if (error || !data) return;

    const score = data.reduce((sum, item) => sum + Number(item.score || 0), 0);
    const maxScore = data.reduce((sum, item) => sum + Number(item.max_score || 0), 0);
    const percent = maxScore ? Math.round((score / maxScore) * 10000) / 100 : 0;
    const exitItems = data.filter((item) => item.section_id === "check");
    const exitScore = exitItems.reduce((sum, item) => sum + Number(item.score || 0), 0);
    const exitMaxScore = exitItems.reduce((sum, item) => sum + Number(item.max_score || 0), 0);
    const exitPercent = exitMaxScore ? exitScore / exitMaxScore : 1;
    const exitNeedsReview = exitItems.length >= 5 && exitPercent < 0.7;
    const needsTeacherReview = data.some((item) => item.needs_teacher_review) || exitNeedsReview;
    const status = statusOverride || (data.length ? "in_progress" : "not_started");
    const submittedAt = status === "submitted" ? new Date().toISOString() : null;

    const attempt = {
      course_id: COURSE_ID,
      student_id: studentId,
      lesson_number: lessonNumber,
      status,
      score,
      max_score: maxScore,
      percent,
      needs_teacher_review: needsTeacherReview,
      started_at: new Date().toISOString()
    };

    if (submittedAt) attempt.submitted_at = submittedAt;

    await window.supabase
      .from("course_lesson_attempts")
      .upsert(attempt, { onConflict: "course_id,student_id,lesson_number" });
  }

  async function submitLessonAttempt(lessonId) {
    const session = await getSession();
    if (!session) return { mode: "local", saved: false };
    if (!(await isStudentSession(session))) {
      return { mode: "supabase", saved: false, skipped: "not_student" };
    }
    const lessonNumber = lessonNumberFromId(lessonId);
    await updateLessonAttempt(session.user.id, lessonNumber, "submitted");
    return { mode: "supabase", saved: true };
  }

  async function loadGradebook() {
    const session = await getSession();
    if (!session) return null;
    const { data, error } = await window.supabase
      .from("course_lesson_score_summary")
      .select("*")
      .eq("course_id", COURSE_ID)
      .order("full_name")
      .order("lesson_number");
    if (error) return null;
    return data || [];
  }

  async function loadStudentResponses(studentId, lessonNumber) {
    const session = await getSession();
    if (!session || !studentId) return null;
    const { data, error } = await window.supabase
      .from("course_question_responses")
      .select("*")
      .eq("course_id", COURSE_ID)
      .eq("student_id", studentId)
      .eq("lesson_number", lessonNumber)
      .order("section_id");
    if (error) return null;
    return data || [];
  }

  async function loadLessonResponses(lessonNumber) {
    const session = await getSession();
    if (!session) return null;
    const { data, error } = await window.supabase
      .from("course_question_responses")
      .select("*")
      .eq("course_id", COURSE_ID)
      .eq("lesson_number", lessonNumber)
      .order("student_id")
      .order("section_id");
    if (error) return null;
    return data || [];
  }

  async function updateQuestionResponse(payload) {
    const session = await getSession();
    if (!session || !payload?.studentId || !payload?.questionId) return { saved: false };
    const lessonNumber = Number(payload.lessonNumber || 1);
    const score = Number(payload.score || 0);
    const maxScore = Number(payload.maxScore ?? 1);

    const { error } = await window.supabase
      .from("course_question_responses")
      .update({
        score,
        max_score: maxScore,
        feedback: payload.feedback || "",
        grading_method: payload.gradingMethod || "teacher_override",
        ai_confidence: payload.confidence ?? null,
        needs_teacher_review: Boolean(payload.needsTeacherReview),
        updated_at: new Date().toISOString()
      })
      .eq("course_id", COURSE_ID)
      .eq("student_id", payload.studentId)
      .eq("lesson_number", lessonNumber)
      .eq("question_id", payload.questionId);

    if (error) return { saved: false, error };
    await updateLessonAttempt(payload.studentId, lessonNumber);
    return { saved: true };
  }

  async function loadTrends(lessonNumber = 1) {
    const session = await getSession();
    if (!session) return null;
    const { data, error } = await window.supabase
      .from("course_class_question_trends")
      .select("*")
      .eq("course_id", COURSE_ID)
      .eq("lesson_number", lessonNumber)
      .order("needs_support", { ascending: false });
    if (error) return null;
    return data || [];
  }

  async function loadClassArchitecture() {
    const session = await getSession();
    if (!session) return null;

    const [sectionsResult, teachersResult, studentsResult] = await Promise.all([
      window.supabase
        .from("course_class_sections")
        .select("*")
        .eq("course_id", COURSE_ID)
        .eq("status", "active")
        .order("name"),
      window.supabase
        .from("course_class_teacher_directory")
        .select("*")
        .eq("course_id", COURSE_ID)
        .eq("status", "active")
        .order("full_name"),
      window.supabase
        .from("course_class_student_directory")
        .select("*")
        .eq("course_id", COURSE_ID)
        .eq("status", "active")
        .order("full_name")
    ]);

    if (sectionsResult.error || teachersResult.error || studentsResult.error) return null;
    return {
      sections: sectionsResult.data || [],
      teachers: teachersResult.data || [],
      students: studentsResult.data || []
    };
  }

  window.CourseData = {
    COURSE_ID,
    getSession,
    ensureEnrollment,
    loadCourseStudents,
    loadCourseTeachers,
    enrollUser,
    saveQuestionResponse,
    submitLessonAttempt,
    loadGradebook,
    loadStudentResponses,
    loadLessonResponses,
    updateQuestionResponse,
    loadTrends,
    loadClassArchitecture
  };
})();
