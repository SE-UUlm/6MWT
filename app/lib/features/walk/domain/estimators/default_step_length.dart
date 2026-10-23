/// Estimates an initial step length from height and optional gender.
/// GPS calibration replaces this estimate during the walk.
double estimateDefaultStepLength({num? heightCm, String? gender}) {
  // Older exports may lack a valid height.
  if (heightCm == null || !heightCm.isFinite || heightCm <= 0) {
    return 0.7;
  }

  var factor = 0.414;
  if (gender == 'male') {
    factor = 0.415;
  } else if (gender == 'female') {
    factor = 0.413;
  }
  return heightCm / 100 * factor;
}
