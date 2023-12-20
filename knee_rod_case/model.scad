include <../BOSL2/std.scad>

$eps = 0.1;
$fa = 4;
$fs = 0.2;

rod_diameter = 16;
rod_cap_length = 6;
rod_metal_length = 202;
rod_length = rod_metal_length + 2 * rod_cap_length;
rod_rounding = 1;

fit_test = false;

tolerance = 0.4;
rounding = 2;
padding = [ 2, 2, 2 ];

finger_size = 20;

module rod(rounding = rod_rounding, tol = 0) {
  cyl(rod_length + 2 * tol, rod_diameter / 2 + tol, rounding = rounding + tol);
}

pocket_width = rod_diameter + 2 * tolerance;
pocket_length = rod_length + 2 * tolerance;
pocket_depth = 2 * rod_diameter / 3 + tolerance;

if (fit_test) {
  rod_case(rod_count = 1, finger_at = pocket_length / 2 - finger_size / 2 - 30);
} else {
  rod_case(rod_count = 2);
}

module rod_case(rod_count, finger_at = 0) {
  finger_depth = pocket_depth;
  finger_offset = finger_size * 2 / 3;

  spacing = padding[0] + finger_size / 2;

  diff("pocket") cuboid(
      [
        2 * padding[0] + pocket_width * rod_count +
            finger_size / 2 * max(2, (2 * rod_count - 1)) +
            padding[0] * (rod_count - 1),
        2 * padding[1] + pocket_length,
        padding[2] + pocket_depth,
      ],
      rounding = rounding, except_edges = TOP) {

    tag("pocket") xcopies(spacing = pocket_width + spacing, n = rod_count) {
      attach(TOP, FRONT, overlap = pocket_depth) rod(tol = tolerance);
      back(finger_at) back(($idx % 2 == 0 ? 1 : -1) * finger_offset)
          attach(TOP, BOTTOM, overlap = finger_depth) cuboid(
              [ finger_size + pocket_width, finger_size, finger_depth + $eps ],
              rounding = finger_depth / 2, except_edges = TOP);
    };
  };
}
