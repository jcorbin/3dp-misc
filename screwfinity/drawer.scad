include <../BOSL2/std.scad>

exterior = [ 39, 80, 30 ];

wall = 1.2;
chamfer = 0.3;

interior = exterior - [ 2*wall, 2*wall, wall + chamfer ];

import("./Screwfinity Drawer Medium.stl");

up(wall/2) {

  // // 2div x
  // cube([wall, interior.y, interior.z], anchor=BOTTOM);

  // // 2div y
  // cube([interior.x, wall, interior.z], anchor=BOTTOM);

  // // 4div
  // cube([wall, interior.y, interior.z], anchor=BOTTOM);
  // cube([interior.x, wall, interior.z], anchor=BOTTOM);

  // 3div y
  fwd(interior.y/6) cube([interior.x, wall, interior.z], anchor=BOTTOM);
  back(interior.y/6) cube([interior.x, wall, interior.z], anchor=BOTTOM);

}
