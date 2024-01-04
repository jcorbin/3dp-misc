include <BOSL2/std.scad>

/* [Hygrometer Metrics] */

// Size of the hygrometer.
hygro_size = [ 44.5, 25.5, 12.5 ];

// Fillet rounding of the hygrometer.
hygro_rounding = 0;

// Padding to allow around the hygromter
hygro_padding = [ 2, 2, 2 ];

/* [Case Metrics] */

case_size = [ 120, 38, 20 ];

case_chamfer = 5;

mount_hole = [ 5.4, 16 ];

mount_hole_at = 50;

/* [Geometry Detail] */

// Hole tolerance.
hole_tol = 0.4;

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustement value for cutouts
$eps = 0.1;

/// implementation

module __customizer_limit__() {}

case_mount() {
  if ($preview) {
    attach(BOTTOM, BOTTOM) ruler();
  }
};

module case_mount(anchor = CENTER, spin = 0, orient = UP) {

  mount_hole_adj = mount_hole_at + mount_hole[0] / 2 + hole_tol;
  mount_hole_spacing = [ -mount_hole_adj, mount_hole_adj ];

  attachable(size = case_size(), anchor = anchor, spin = spin,
             orient = orient) {

    diff(remove="mount") case() {
      tag("mount")
        attach(TOP, BOTTOM, overlap = $eps + $parent_size[2])
        cuboid(size = [
          hygro_size[0] + 2*hole_tol,
          hygro_size[1] + 2*hole_tol,
          $eps + $parent_size[2] + $eps
        ], rounding = hygro_rounding + hole_tol);


      tag("mount")
        xcopies(spacing=mount_hole_spacing)
        attach(BOTTOM, TOP, overlap = mount_hole[1])
          cyl(l = mount_hole[1] + $eps, d = mount_hole[0] + 2*hole_tol);

    };

    children();

  }

}

function case_size() = [
  max(case_size[0], hygro_size[0] + 2*hole_tol + hygro_padding[0] + case_chamfer),
  max(case_size[1], hygro_size[1] + 2*hole_tol + hygro_padding[1] + case_chamfer),
  max(case_size[2], hygro_size[2] + 2*hole_tol + hygro_padding[2]),
];

module case (anchor = CENTER, spin = 0, orient = UP) {
  size = case_size;

  attachable(size = size, anchor = anchor, spin = spin, orient = orient) {

    cuboid(size = size, chamfer = case_chamfer, except_edges=BOTTOM);

    children();

  }

}
