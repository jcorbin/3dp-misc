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
minimal = true;

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
  length = finger_size / 2 + 30;
  diff(remove = "cut")
      rod_case(rod_count = 1, finger_at = pocket_length / 2 - length) {
    tag("cut") attach(FRONT, BACK, overlap = $case_size[1] - length) cube([
      $case_size[0] + 2 * $eps,
      $case_size[1] + 2 * $eps,
      $case_size[2] + 2 * $eps,
    ]);
  };
} else if (minimal) {
  rod_case(rod_count = 2, minimize = true);
} else {
  rod_case(rod_count = 2);
}

module rod_case(rod_count, minimize = false, finger_at = 0, anchor = CENTER,
                spin = 0, orient = UP) {
  finger_depth = pocket_depth;
  finger_offset = finger_size * 2 / 3;
  finger_rounding = finger_depth / 2;

  spacing = padding[0] + (minimize ? 0 : finger_size / 2);

  cut_size = [
    minimize ? (finger_size + pocket_width) / 2 : finger_size + pocket_width,
    finger_size,
    finger_depth + $eps,
  ];

  $case_size = [
    2 * padding[0] + pocket_width * rod_count + spacing * (rod_count - 1) +
        (minimize ? 0 : finger_size),
    2 * padding[1] + pocket_length,
    padding[2] + pocket_depth,
  ];

  attachable(size = $case_size, anchor = anchor, spin = spin, orient = orient) {
    tag_scope("rod_case") diff("pocket")
        cuboid($case_size, rounding = rounding, except_edges = TOP) {
      tag("pocket") xcopies(spacing = pocket_width + spacing, n = rod_count) {
        attach(TOP, FRONT, overlap = pocket_depth) rod(tol = tolerance);
        back(finger_at)
            back(($idx % 2 == 0 ? 1 : -1) * finger_offset) if (minimize) {
          parity_step(cut_size[0] / 2, $idx) attach(TOP, BOTTOM,
                                                    overlap = finger_depth)
              cuboid(cut_size, rounding = finger_rounding, except_edges = TOP);
        }
        else {
          attach(TOP, BOTTOM, overlap = finger_depth)
              cuboid(cut_size, rounding = finger_rounding, except_edges = TOP);
        }
      };
    }

    children();
  }
}

module parity_step(by, i) {
  if (i % 2 == 0) {
    left(by) children();
  } else {
    right(by) children();
  }
}
