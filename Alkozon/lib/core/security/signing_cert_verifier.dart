class SigningCertVerifier {
  static String normalizeSha256(String raw) {
    return raw.replaceAll(':', '').toLowerCase().trim();
  }

  static bool isAllowed(String certSha256, Iterable<String> allowedFingerprints) {
    final normalized = normalizeSha256(certSha256);
    if (normalized.isEmpty) {
      return false;
    }
    for (final allowed in allowedFingerprints) {
      if (normalizeSha256(allowed) == normalized) {
        return true;
      }
    }
    return false;
  }
}
