// Parametric U bracket

include <BOSL2/std.scad>
include <BOSL2/screws.scad>

/* [Parameters] */

// Nominal diameter of the held thing.
diameter = 14;

// Wall thickness of the bracket.
thickness = 4;

// Mounting tab/ear length out from the main U.
ear_length = 14;

// Inner and outer chamfer where the bracket turns into each mounting tab/ear.
chamfer = 3;

// Bracket width along the held thing.
width = 14;

// Mounting screw spec.
screw = "#6";

// Screw head type, "flat" will generate a countersunk hole.
screw_head = "flat";

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustment value for cutouts
$eps = 0.01;

/// implementation

module holder(id, od, h, anchor = CENTER, orient = UP, spin = 0) {
  attachable(size=[od, od, h], anchor = anchor, orient = orient, spin = spin) {

    // TODO probably better to extrud our own U-shaped path
    tag_scope("holder")
    fwd(od/2)
    union() {
      back(od/2)
      back_half(z=-(od - id)/2)
        tube(h=h, id=diameter, od=od);

      back_half()
      diff() cube([od, od, h], center=true)
        tag("remove")
          cube([diameter, od + 2*$eps, h + 2*$eps], center=true);

    }

    children();
  }
}

module tab(od, h, extra = $eps, chamfer=0, anchor = CENTER, orient = UP, spin = 0) {
  attachable(size=[od, od, h], anchor = anchor, orient = orient, spin = spin) {
    tag_scope("tab")
    diff(remove="hole") union() {

      front_half(y=$eps)
        cyl(d=od, h=h);

      back(extra)
      back_half(y=extra)
        cube([od, od + extra, h], center=true);

      if (chamfer > 0) {
        up(h/2)
        back(od/2 + extra)
        xrot(45)
          cube([od, chamfer + 2*$eps, chamfer + 2*$eps], center=true);
      }

      attach(TOP, BOTTOM, overlap=od-$eps)
      tag("hole")
        screw_hole(spec = screw, head = screw_head, thread = false, length = od);
    }

    children();
  }
}

xrot(-90)
diff() holder(
  id = diameter,
  od = diameter + thickness * 2,
  h = width,
  orient=FRONT
) {

  fwd((diameter + thickness)/2) {
    attach(LEFT, BACK)
    zrot(90)
      tab(od=ear_length, h=thickness, chamfer=chamfer);
    attach(RIGHT, BACK)
    zrot(-90)
      tab(od=ear_length, h=thickness, chamfer=chamfer);
  }

  if (chamfer > 0) {
    fwd(diameter/2 + thickness)
    xcopies(spacing=[-diameter/2, diameter/2])
    tag("remove")
    zrot(45)
      cube([chamfer + 2*$eps, chamfer + 2*$eps, width + 2*$eps], center=true);
  }

}
