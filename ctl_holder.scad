include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

use <grid2.scad>

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

module grip() {
  w = 3;

  inner_path = offset(turtle([
    "move", 20,
    "arcleft", 20, 90 + 70,
    "move", 60
  ]), r=w);
  outer_path = offset(turtle([
    "move", 20 + 20 + 11, // TODO maths > magic
    "left", 90,
    "move", 30,
    "left", 70,
    "move", 60 + 26 // TODO maths > magic
  ]), r=-w);

  offset_sweep(
    concat(inner_path, reverse(outer_path)),
    height=25,
    bottom=os_chamfer(width=2),
    top=os_chamfer(width=2)
  );

}

down(7/2 + 30) {
  grid_copies(spacing=42, n=[4, 2])
    grid_foot();

  conv_hull()
  up(4.75)
  down(7/2)
    grid_body([42*4, 42*2], h=7, anchor=BOTTOM)
    attach(TOP, BOTTOM, overlap=$eps)
    fwd(15)
    cuboid([42, 42, 30+2*$eps],
      rounding=8, edges=[
        [0, 0, 1, 1], // yz -- +- -+ ++
        [0, 0, 1, 1], // xz
        [1, 1, 1, 1], // xy
      ]);
}

fwd(15)
fwd(36/2)
back(3)
down(3)
up(52) // TODO maths > magic
left(12.5)
yrot(90)
  grip();
