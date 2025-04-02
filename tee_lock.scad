include <BOSL2/std.scad>;

/* [Parameters] */

descent = 150;

hole_tolerance = 0.5;

chamfer = 3;

hole_size = [ 18, 18 ];

mount_size = [ 150, 30, 30 ];

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid
// coincident face flicker.
$eps = 0.01;

/// dispatch / integration

module mount(anchor = CENTER, spin = 0, orient = UP) {
  bore_size = [
    hole_size.x + hole_tolerance * 2, hole_size.y + hole_tolerance * 2,
    mount_size.z + 2 *
    2*$eps
  ];
  attachable(anchor, spin, orient, size = mount_size) {
    diff() cuboid(mount_size, chamfer = chamfer) {

      ch = chamfer + hole_tolerance;
      // #fwd(9)
      down(ch/2)
      tag("remove")
        cuboid(bore_size - [0, 0, ch], chamfer=ch, edges = "Z")
        attach(TOP, BOTTOM, overlap=$eps)
        prismoid(
          size1=[bore_size.x, bore_size.y],
          size2=[bore_size.x + ch, bore_size.y + ch],
          h=ch + $eps,
          chamfer=ch
        )
        ;
    }

    children();
  }
}

module lock(anchor = CENTER, spin = 0, orient = UP) {
  size = [
    mount_size.x - 2*chamfer,
    hole_size.y,
    descent + hole_size.y
  ];
  attachable(anchor, spin, orient, size=size) {
    up(descent/2)
    cuboid([
      mount_size.x - 2*chamfer,
      hole_size.y,
      hole_size.y
    ], chamfer=chamfer)
      attach(BOTTOM, TOP, overlap=chamfer + $eps)
      cuboid([
        hole_size.x,
        hole_size.y,
        descent + chamfer + $eps
      ], chamfer=chamfer, edges=[
        [1, 1, 0, 0], // yz -- +- -+ ++
        [1, 1, 0, 0], // xz
        [1, 1, 1, 1], // xy
      ]);


    children();
  }
}

if ($preview) {

  left_half(s=descent*20)
  mount()
    attach(CENTER, BOTTOM, overlap=descent-mount_size.z/2)
    lock();

  // mount();
  // {
  //   // position(TOP) #sphere(1);
  //   // %show_anchors();
  //   #cube($parent_size, center=true);
  // }

} else {
  spacing = 5;
  back(hole_size.y/2 + spacing)
  left(mount_size.y/2 + hole_size.x/2 + spacing)
  mount(anchor=BOTTOM, spin=90);
  lock(orient=FWD, anchor=FRONT);
}

// module XXX(anchor = CENTER, spin = 0, orient = UP) {
//   size = [XXX.x, XXX.z, XXX.y];
//   attachable(anchor, spin, orient, size=size) {
//     // XXX geometry; e.g. import to remix/rework
//     // down(size.z/2)
//     // back(size.y/2)
//     // left(size.x/2)
//     //   import("XXX.stl");
//     children();
//   }
// }
