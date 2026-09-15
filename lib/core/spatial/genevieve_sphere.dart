import 'dart:math';

class GenevieveSphere {
  static List<double> computeCartesianCoordinates(double radius, double theta, double phi) {
    final x = radius * sin(theta) * cos(phi);
    final y = radius * sin(theta) * sin(phi);
    final z = radius * cos(theta);
    return [x, y, z];
  }
}
