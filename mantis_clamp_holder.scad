include <BOSL2/std.scad>;

use <grid2.scad>

// Platform size in grid units.
platform_size = [ 1, 2, 1 ];

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

stand_size = [ 80.85, 18.92, 32 ];

module stand(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[stand_size.x, stand_size.z, stand_size.y]) {
    xrot(-90)
    down(stand_size.z/2)
    back(stand_size.y/2)
    left(stand_size.x/2)
      import("../Downloads/mantis-clamp-model_files/STABLE (TESTED)/Tension Stand.stl");
    children();
  }
}

module holder(anchor = CENTER, spin = 0, orient = UP) {
  gh = platform_size.z * 7;
  fh = struct_val(grid_foot(), "height");

  h = 7 + 46 * sqrt(2)/2 - 7.25;

  attachable(anchor, spin, orient, size=[42, 2*42, h], anchors=[
    // TODO named_anchor("mount")
  ]) {

    down(h/2)
    up(fh) {
      grid_copies(spacing=42, n=[platform_size.x, platform_size.y])
      up($eps)
        grid_foot(h=$eps, anchor=TOP);

      grid_body(42*platform_size, h=gh, anchor=BOTTOM) {
        top_half() up(14.8/2) {
          fwd(31)
          xrot(-90)
          bottom_half()
          tube(id=14.8, od=18.8, h=41, orient=LEFT);

          translate(1*[0, -sqrt(2), -sqrt(2)])
          down(6.5)
          fwd(31)
          xrot(45)
          diff()
          cuboid([ 41.5, 46, 46, ], anchor=FRONT+TOP) {
            tag("remove")
            back(5)
            attach(TOP, BOTTOM, overlap=4)
              cuboid(size=[45, 45, 14], rounding=45/2, edges=[
                [0, 0, 0, 0], // yz -- +- -+ ++
                [0, 0, 0, 0], // xz
                [1, 1, 0, 0], // xy
              ]);

            edge_mask("X", except=[FRONT, BOTTOM])
              rounding_edge_mask(l=42, r=16);
              // chamfer_edge_mask(l=41, chamfer=8);

          }
        }
      }
    }

    children();
  }
}


// left(42) zrot(90) stand();

diff() holder() {

  tag("remove")
    // back(15)
    fwd(44/2 + 7 - 5)
    up(7-1)
    up(14/2)
    position(BOTTOM+BACK)
    cuboid([14, 44 + 10, 14], rounding=2, edges="Y");

}

// import("../Downloads/mantis-clamp-model_files/STABLE (TESTED)/Mantis Clamp Hex-Dial - 0_25 [RECOMMENDED].stl");

// {
//   // position(TOP) #sphere(1);
//   // %show_anchors();
//   #cube($parent_size, center=true);
// }
