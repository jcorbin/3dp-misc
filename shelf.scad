include <BOSL2/std.scad>;

/* [Body dimension] */

// size = [ 228, 228, 4 ];
size = [ 209, 209, 4 ];

chamfer = 1;

corner = 0;

rib = [ 1, 158, 2 ];

rib_every = 30;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

diff()
cuboid(size=size, chamfer=chamfer) {

  if (corner > 0) {
    down(size.z/2)
    corner_mask(except=DOWN)
      cuboid(size=[ corner, corner, size.z + 2*$eps ], chamfer=chamfer, edges="Z");
  }

  if (rib.x * rib.y * rib.z > 0) {

    num_ribs = floor(size.y / rib_every);

    tag("keep")
      xcopies(spacing=rib_every, l=size.y)
      let (
        rib_len = ($idx == 0 || $idx == num_ribs) ? rib.y : size.y - 2*chamfer
      )
      attach(TOP, BOTTOM)
      prismoid(
        size1=[rib.x + 2*rib.z, rib_len],
        size2=[rib.x,           rib_len - 2*rib.z],
        h=rib.z
      );

    tag("keep")
      ycopies(spacing=rib_every, l=size.y)
      let (
        rib_len = ($idx == 0 || $idx == num_ribs) ? rib.y : size.y - 2*chamfer
      )
      zrot(90)
      attach(TOP, BOTTOM)
      prismoid(
        size1=[rib.x + 2*rib.z, rib_len],
        size2=[rib.x,           rib_len - 2*rib.z],
        h=rib.z
      );

  }

}
