// Centralised validation rules for account and profile fields.
//
// All methods return null on success or a human-readable error string on
// failure. Using a module rather than inline checks ensures the auth screen
// and the edit-profile dialog enforce exactly the same constraints.

/// Validates an email address.
///
/// Checks that the field is non-empty and matches a basic RFC 5322-compatible
/// pattern.  Supabase will perform its own canonical check server-side;
/// this provides immediate, clear feedback in the UI.
String? validateEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) return 'Email is required.';
  // Minimal but practical email regex: local@domain.tld
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(trimmed)) return 'Enter a valid email address.';
  return null;
}

/// Validates a password against the policy used in Supabase Auth.
///
/// Requirements (kept permissive to match the default Supabase policy):
/// - Minimum 6 characters (Supabase default minimum).
/// - Maximum 72 characters (bcrypt hard limit).
String? validatePassword(String password) {
  if (password.isEmpty) return 'Password is required.';
  if (password.length < 6) return 'Password must be at least 6 characters.';
  if (password.length > 72) return 'Password must be 72 characters or fewer.';
  return null;
}

/// Validates a display name.
///
/// - Required field.
/// - 1–50 characters after trimming.
String? validateName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Name is required.';
  if (trimmed.length > 50) return 'Name must be 50 characters or fewer.';
  return null;
}

/// Validates and normalises a profile handle.
///
/// Rules:
/// - Required field (must not be empty or whitespace only).
/// - 3–30 characters (excluding a leading `@` if the user typed it).
/// - Only letters, digits, underscores, and hyphens are permitted.
/// - Automatically prepends `@` when returning the canonical form via
///   [normaliseHandle]; the raw check is done on the bare handle.
///
/// Returns `null` on success or an error string.
String? validateHandle(String handle) {
  // Strip a leading @ so users can type it either way.
  final bare = handle.trim().replaceFirst(RegExp(r'^@'), '');
  if (bare.isEmpty) return 'Handle is required.';
  if (bare.length < 3) return 'Handle must be at least 3 characters.';
  if (bare.length > 30) return 'Handle must be 30 characters or fewer.';
  final handleRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
  if (!handleRegex.hasMatch(bare)) {
    return 'Handle may only contain letters, numbers, underscores, and hyphens.';
  }
  return null;
}

/// Returns the canonical `@`-prefixed handle for storage.
///
/// Strips leading/trailing whitespace and a duplicate leading `@`.
String normaliseHandle(String handle) {
  final bare = handle.trim().replaceFirst(RegExp(r'^@'), '');
  return '@$bare';
}
