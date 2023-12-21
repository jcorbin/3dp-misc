include <../BOSL2/std.scad>

/// geometry config

$eps = 0.1;
$fa = 4;
$fs = 0.2;

/// mode

fit_test = false;
minimal = true;

/// settings

rod_diameter = 16;
rod_cap_length = 6;
rod_metal_length = 202;
rod_rounding = 1;

case_tol = 0.4;
cover_tol = 0.2;

case_rounding = 2;
case_padding = [ 2, 2, 2 ];

cover_rounding = 2.5;
cover_padding = [ 2.5, 2.5, 2.5 ];

finger_size = 20;

/// implementation

rod_length = rod_metal_length + 2 * rod_cap_length;

pocket_width = rod_diameter + 2 * case_tol;
pocket_length = rod_length + 2 * case_tol;
pocket_depth = 2 * rod_diameter / 3 + case_tol;

finger_depth = pocket_depth;
finger_offset = finger_size * 2 / 3;
finger_rounding = finger_depth / 2;

module rod(rounding = rod_rounding, tol = 0, extra = 0) {
  cyl(rod_length + 2 * tol + extra, rod_diameter / 2 + tol,
      rounding = rounding > 0 ? rounding + tol : 0);
}

if (minimal) {
  xrot(180) diff("cut")
      case_pair(padding = cover_padding, case_padding = case_padding,
                rounding = cover_rounding, case_rounding = case_rounding) {
    if (fit_test) {
      cut_size = [
        $case_size[0] + $cover_size[0] + 10 + 2 * $eps,
        $cover_size[1] * 0.7,
        $cover_size[2] + 2 * $eps,
      ];
      tag("cut") attach(FRONT, BACK, overlap = cut_size[1] / 2)
          cube(cut_size, center = true);
      tag("cut") attach(BACK, FRONT, overlap = cut_size[1] / 2)
          cube(cut_size, center = true);
    }
  }
} else {
  if (fit_test) {
    length = finger_size / 2 + 30;
    diff("cut")
        rod_case(rod_count = 1, finger_at = pocket_length / 2 - length) {
      tag("cut") attach(FRONT, BACK, overlap = $case_size[1] - length) cube([
        $case_size[0] + 2 * $eps,
        $case_size[1] + 2 * $eps,
        $case_size[2] + 2 * $eps,
      ]);
    };
  } else {
    rod_case(rod_count = 2, padding = case_padding, rounding = case_rounding);
  }
}

module case_pair(case_padding, padding, case_rounding, rounding,
                 anchor = CENTER, spin = 0, orient = UP) {

  $case_size = rod_case_size(2, true, case_padding);
  $cover_size = rod_cover_size(padding, cover_tol);

  attachable(
      size =
          [
            $cover_size[0] + 10 + $case_size[0], $cover_size[1], $cover_size[2]
          ],
      anchor = anchor, spin = spin, orient = orient) {

    right($case_size[0] / 2) right(5)
        rod_case_cover(rod_count = 2, tol = cover_tol, padding = padding,
                       case_padding = case_padding, rounding = rounding,
                       case_rounding = case_rounding) {

      xrot(180) down(($cover_size - $case_size)[2] / 2)
          attach(LEFT, RIGHT, overlap = -10)
              rod_case(rod_count = 2, minimize = true, padding = case_padding,
                       rounding = case_rounding);
    };

    children();
  }
}

function rod_cover_size(padding, tol,
                        $case_size = rod_case_size(2, true, case_padding)) =
    [
      $case_size[0] + 2 * (padding[0] + tol),
      $case_size[1] + 2 * tol,
      rod_diameter + 2 * (padding[2] + case_tol),
    ];

module rod_case_cover(rod_count = 2, tol = 0, finger_at = 0,
                      padding = [ 2, 2, 2 ], case_padding = [ 2, 2, 2 ],
                      rounding = 2, case_rounding = 2, anchor = CENTER,
                      spin = 0, orient = UP) {

  $case_size = rod_case_size(2, true, case_padding);
  $cover_size = rod_cover_size(padding, tol);

  spacing = rod_case_spacing(case_padding, true);

  attachable(size = $cover_size, anchor = anchor, spin = spin,
             orient = orient) {
    tag_scope("rod_case_cover") diff("slide")
        cuboid($cover_size, rounding = rounding) {
      tag("slide") attach(BOTTOM, BOTTOM, norot = true, overlap = $eps)
          cuboid($case_size + [ 0, 2 * ( padding[1] +  $eps ), 0 ], rounding = case_rounding,
                 edges = BOTTOM) {
        xcopies(spacing = pocket_width + spacing,
                n = 2) attach(TOP, FRONT, overlap = pocket_depth)
            rod(tol = case_tol, extra = 2 * (case_padding[1] + padding[1] + $eps), rounding = 0);
      };
    }

    children();
  }
}

function rod_case_spacing(padding, minimize) = padding[0] +
                                               (minimize ? 0 : finger_size / 2);

function rod_case_size(rod_count, minimize, padding) = [
  2 * padding[0] + pocket_width * rod_count +
      rod_case_spacing(padding, minimize) * (rod_count - 1) +
      (minimize ? 0 : finger_size),
  2 * padding[1] + pocket_length,
  padding[2] + pocket_depth,
];

module rod_case(rod_count, minimize = false, finger_at = 0,
                padding = [ 2, 2, 2 ], rounding = 2, anchor = CENTER, spin = 0,
                orient = UP) {

  cut_size = [
    minimize ? (finger_size + pocket_width) / 2 : finger_size + pocket_width,
    finger_size,
    finger_depth + $eps,
  ];

  $case_size = rod_case_size(rod_count, minimize, padding);

  attachable(size = $case_size, anchor = anchor, spin = spin, orient = orient) {
    tag_scope("rod_case") diff("pocket")
        cuboid($case_size, rounding = rounding, except_edges = TOP) {
      tag("pocket")
          xcopies(spacing = pocket_width + rod_case_spacing(padding, minimize),
                  n = rod_count) {
        attach(TOP, FRONT, overlap = pocket_depth) rod(tol = case_tol);
        back(finger_at)
            back(($idx % 2 == 0 ? 1 : -1) * finger_offset) if (minimize) {
          left(($idx % 2 == 0 ? 1 : -1) * cut_size[0] /
               2) attach(TOP, BOTTOM, overlap = finger_depth)
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
