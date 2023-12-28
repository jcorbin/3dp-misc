include <../BOSL2/std.scad>

/// mode

// Enable to generate a minimal fit-test model, rather than a full case
fit_test = false;

// Enable to generate a minimal case with a slide cover, or disable to generate
// a simpler/wider tray with finger pockets.
slide_case = true;

/// settings

// How many rods to fit in the case
rod_count = 2; // [2:2:64]

// Diamter of the rod's aluminium amin body (mm)
rod_diameter = 16;

// Length of the rod's aluminium main body (mm)
rod_metal_length = 202;

// Length of the rod's plastic cap (mm)
rod_cap_length = 6;

// Radius of the rod's plastic endcap rounding (mm)
rod_rounding = 1;

// Expected size of user fingers (mm).
// When generating just a tray (not slide case mode), this alsow controls
// additonal width padding before/between/after each rod slot.
finger_size = 20;

// Depth of the rod slot as a percentage of rod diameter.
// A deeper slot will cause the rods to pop/stick in, but anything pas 60-70%
// can be too tight of a fit for insertion.
slot_depth = 55; // [10:1:90]

// Tolerance to allow where the case meets the rod
case_tol = 0.4; // 0.1

// Tolerance to allow where the slide cover meets the case
cover_tol = 0.1; // 0.1

// Fillet rounding radius for the case
case_rounding = 2;

// Fillet rounding radius for the slide cover
cover_rounding = 2;

// XYZ padding for the case
case_padding = [ 2, 2, 2 ];

// XYZ padding for the slide cover
cover_padding = [ 4, 3, 2 ];

// Enable to use a flat chamfer on the case, instead of curved roudning
case_chamfer = false;

// Enable to use a flat chamfer on the slide cover, instead of curved roudning
cover_chamfer = false;

/// geometry config

module __customizer_limit__() {}

$eps = 0.1;
$fa = 4;
$fs = 0.2;

/// implementation

rod_length = rod_metal_length + 2 * rod_cap_length;

pocket_width = rod_diameter + 2 * case_tol;
pocket_length = rod_length + 2 * case_tol;
pocket_depth = rod_diameter * slot_depth / 100 + case_tol;

finger_depth = pocket_depth;
finger_offset = finger_size * 2 / 3;
finger_rounding = finger_depth / 2;

module rod(rounding = rod_rounding, tol = 0, extra = 0) {
  cyl(rod_length + 2 * tol + extra, rod_diameter / 2 + tol,
      rounding = rounding > 0 ? rounding + tol : 0);
}

if (slide_case) {
  xrot(180) diff("cut")
      case_pair(rod_count = rod_count, padding = cover_padding,
                case_padding = case_padding, rounding = cover_rounding,
                case_rounding = case_rounding) {
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
}

else {
  if (fit_test) {
    length = finger_size / 2 + 30;
    diff("cut") rod_case(rod_count = rod_count,
                         finger_at = pocket_length / 2 - length) {
      tag("cut") attach(FRONT, BACK, overlap = $case_size[1] - length) cube([
        $case_size[0] + 2 * $eps,
        $case_size[1] + 2 * $eps,
        $case_size[2] + 2 * $eps,
      ]);
    };
  } else {
    rod_case(rod_count = rod_count, padding = case_padding,
             rounding = case_rounding);
  }
}

module case_pair(case_padding, padding, case_rounding, rounding, rod_count = 2,
                 anchor = CENTER, spin = 0, orient = UP) {

  $case_size = rod_case_size(rod_count, true, case_padding);
  $cover_size = rod_cover_size(rod_count, padding, cover_tol);

  attachable(
      size =
          [
            $cover_size[0] + 10 + $case_size[0], $cover_size[1], $cover_size[2]
          ],
      anchor = anchor, spin = spin, orient = orient) {

    right($case_size[0] / 2) right(5)
        rod_case_cover(rod_count = rod_count, tol = cover_tol,
                       padding = padding, case_padding = case_padding,
                       rounding = rounding, case_rounding = case_rounding) {

      xrot(180) down(($cover_size - $case_size)[2] / 2)
          attach(LEFT, RIGHT, overlap = -10)
              rod_case(rod_count = rod_count, minimize = true,
                       padding = case_padding, rounding = case_rounding);
    };

    children();
  }
}

function rod_cover_size(rod_count, padding, tol,
                        $case_size = rod_case_size(rod_count, true,
                                                   case_padding)) =
    [
      $case_size[0] + 2 * (padding[0] + tol),
      $case_size[1] + 2 * tol,
      rod_diameter + 2 * (padding[2] + case_tol),
    ];

module rod_case_cover(rod_count = 2, tol = 0, finger_at = 0,
                      padding = [ 2, 2, 2 ], case_padding = [ 2, 2, 2 ],
                      rounding = 2, case_rounding = 2, anchor = CENTER,
                      spin = 0, orient = UP) {

  $case_size = rod_case_size(rod_count, true, case_padding);
  $cover_size = rod_cover_size(rod_count, padding, tol);
  slide_size = $case_size + [ 2 * tol, 2 * (padding[1] + tol + $eps), 2 * tol ];

  spacing = rod_case_spacing(case_padding, true);

  attachable(size = $cover_size, anchor = anchor, spin = spin,
             orient = orient) {
    tag_scope("rod_case_cover") diff("slide")
        cuboid($cover_size, rounding = cover_chamfer ? 0 : rounding,
               chamfer = cover_chamfer ? rounding : 0) {
      tag("slide") attach(BOTTOM, BOTTOM, norot = true, overlap = $eps)
          cuboid(slide_size, rounding = case_chamfer ? 0 : case_rounding,
                 chamfer = case_chamfer ? rounding : 0, edges = BOTTOM) {
        xcopies(spacing = pocket_width + spacing, n = rod_count)
            attach(TOP, FRONT, overlap = pocket_depth)
                rod(tol = case_tol,
                    extra = 2 * (case_padding[1] + padding[1] + $eps),
                    rounding = 0);
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

module rod_case(rod_count = 2, minimize = false, finger_at = 0,
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
        cuboid($case_size, rounding = case_chamfer ? 0 : rounding,
               chamfer = case_chamfer ? rounding : 0, except_edges = TOP) {
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
