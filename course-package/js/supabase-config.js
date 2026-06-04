// Shared Altus Courses backend.
// Uses the existing Driver's Ed Supabase project.
const SUPABASE_URL = "https://vulzhiifgxrimpquhsvg.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ1bHpoaWlmZ3hyaW1wcXVoc3ZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2NzY5MzksImV4cCI6MjA5MTI1MjkzOX0.6sagUIwX_WCmgZgG4crfDx46GjK0boBbarAuxmu5YQM";

var supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
