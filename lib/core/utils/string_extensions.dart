extension SafeSubstring on String {
  /// Safely extracts a substring preventing RangeError crashes
  /// if the requested indices are out of bounds.
  String safeSubstring(int start, [int? end]) {
    if (isEmpty) return this;
    int safeStart = start < 0 ? 0 : start;
    if (safeStart > length) safeStart = length;
    
    int safeEnd = end ?? length;
    if (safeEnd < 0) safeEnd = 0;
    if (safeEnd > length) safeEnd = length;
    if (safeEnd < safeStart) safeEnd = safeStart;
    
    return substring(safeStart, safeEnd);
  }
}
