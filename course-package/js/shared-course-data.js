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

    const question = payload.question || {};
    const result = payload.result || {};
    const lessonNumber = lessonNumberFromId(payload.lessonId);
    const maxScore = Number(result.maxScore || 1);
    const score = Number(result.score || 0);

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
      grading_method: question.grading === "ai_rubric" ? "ai_rubric" : "deterministic",
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
      .from("course_lesson_score_summary")
      .select("student_id, full_name, username, email")
      .eq("course_id", COURSE_ID)
      .order("full_name");
    if (error) return null;
    const byId = {};
    for (const row of data || []) {
      byId[row.student_id] = {
        id: row.student_id,
        full_name: row.full_name,
        username: row.username,
        email: row.email
      };
    }
    return Object.values(byId);
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

  async function updateLessonAttempt(studentId, lessonNumber) {
    const { data, error } = await window.supabase
      .from("course_question_responses")
      .select("score,max_score,needs_teacher_review")
      .eq("course_id", COURSE_ID)
      .eq("student_id", studentId)
      .eq("lesson_number", lessonNumber);

    if (error || !data) return;

    const score = data.reduce((sum, item) => sum + Number(item.score || 0), 0);
    const maxScore = data.reduce((sum, item) => sum + Number(item.max_score || 0), 0);
    const percent = maxScore ? Math.round((score / maxScore) * 10000) / 100 : 0;
    const needsTeacherReview = data.some((item) => item.needs_teacher_review);
    const status = data.length ? "in_progress" : "not_started";

    await window.supabase
      .from("course_lesson_attempts")
      .upsert({
        course_id: COURSE_ID,
        student_id: studentId,
        lesson_number: lessonNumber,
        status,
        score,
        max_score: maxScore,
        percent,
        needs_teacher_review: needsTeacherReview,
        started_at: new Date().toISOString()
      }, { onConflict: "course_id,student_id,lesson_number" });
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

  async function loadTrends() {
    const session = await getSession();
    if (!session) return null;
    const { data, error } = await window.supabase
      .from("course_class_question_trends")
      .select("*")
      .eq("course_id", COURSE_ID)
      .eq("lesson_number", 1)
      .order("needs_support", { ascending: false });
    if (error) return null;
    return data || [];
  }

  window.CourseData = {
    COURSE_ID,
    getSession,
    ensureEnrollment,
    loadCourseStudents,
    enrollUser,
    saveQuestionResponse,
    loadGradebook,
    loadStudentResponses,
    loadTrends
  };
})();
