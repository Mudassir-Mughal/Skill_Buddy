import 'dart:math';

/// Calculate cosine similarity between two vectors
double cosineSimilarity(List<int> a, List<int> b) {
  if (a.length != b.length) {
    throw ArgumentError("Vectors must be the same length");
  }

  // dot product
  int dot = 0;
  for (int i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
  }

  // magnitude
  double magA = sqrt(a.fold(0, (sum, val) => sum + val * val));
  double magB = sqrt(b.fold(0, (sum, val) => sum + val * val));

  if (magA == 0 || magB == 0) return 0.0;

  return dot / (magA * magB);
}
