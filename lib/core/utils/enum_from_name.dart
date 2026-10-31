/// Parses a persisted enum name into the corresponding enum value.
///
/// Returns [fallback] when [raw] is null or does not match any entry of
/// [values], so corrupted or outdated persisted values can never crash
/// the app at startup.
T enumFromName<T extends Enum>(List<T> values, String? raw, T fallback) {
  if (raw == null) {
    return fallback;
  }
  for (final T value in values) {
    if (value.name == raw) {
      return value;
    }
  }
  return fallback;
}
