// Parametric U bracket

include <BOSL2/std.scad>
include <BOSL2/screws.scad>

/* [Parameters] */

// Nominal diameter of the held thing.
diameter = 14;

// Bracket width along the held thing; if zero, use diameter.
width = 0;

// Mounting tab/ear length out from the main U; if zero, use diameter.
ear_length = 0;

// Wall thickness of the bracket.
thickness = 3;

// Inner and outer chamfer where the bracket turns into each mounting tab/ear.
chamfer = 3;

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

function bracket_profile(
  diameter,
  ear_length=0,
  thickness=1,
  chamfer=1
) = let (
  tab_width = ear_length == 0 ? diameter : ear_length,

  od = diameter + thickness * 2,
  or = od/2,
  ir = diameter/2,

  // TODO see if we can have BOSL2/rounding.scad simplify this
  chamadj = thickness/sqrt(8),
  icham = chamfer - chamadj,
  ocham = chamfer + chamadj,
  iskip = sqrt(icham^2/2),
  oskip = sqrt(ocham^2/2),
  iarm = tab_width - iskip,
  oarm = tab_width - oskip,
  ileg = or - iskip,
  oleg = or - oskip
) turtle([
  "move", oarm + thickness,
  "left", 45,
  "move", ocham,
  "left", 45,
  "move", oleg,
  "arcright", ir, 180,
  "move", oleg,
  "left", 45,
  "move", ocham,
  "left", 45,
  "move", thickness + oarm,

  "left", 90,
  "move", thickness,
  "left", 90,
  "move", iarm,
  "right", 45,
  "move", icham,
  "right", 45,
  "move", ileg - thickness,
  "arcleft", or, 180,
  "move", ileg - thickness,
  "right", 45,
  "move", icham,
  "right", 45,
  "move", iarm,
  "left", 90,
  "move", thickness,
], state=[-(or + tab_width), -or]);

module ubracket(
  diameter,
  width=0,
  ear_length=0,
  thickness=1,
  chamfer=1,
  anchor = CENTER, orient = UP, spin = 0) {

  h = width == 0 ? diameter : width;
  tab_width = ear_length == 0 ? diameter : ear_length;

  profile = bracket_profile(
    diameter,
    ear_length=ear_length,
    thickness=thickness,
    chamfer=chamfer
  );
  profile_bounds = pointlist_bounds(profile);
  profile_size = profile_bounds[1] - profile_bounds[0];
  size = [profile_size.x, profile_size.y, h];

  attachable(
    path=profile, h=h,
    anchors = [
      named_anchor("left_tab", [
        profile_bounds[0].x + tab_width/2,
        profile_bounds[0].y + thickness,
        0], orient=BACK),
      named_anchor("right_tab", [
        profile_bounds[1].x - tab_width/2,
        profile_bounds[0].y + thickness,
        0], orient=BACK)
    ],
    anchor = anchor, orient = orient, spin = spin) {

    intersect("mask")
    linear_sweep(profile, h, center=true)
      tag("mask")
        cuboid(size, rounding=h/2, edges="Y");

    children();
  }
}

module attach_copies(at, to, overlap, norot=false) {
  req_children($children);
  assert(is_list(at));
  for ($idx = idx(at)) {
    attach(at[$idx], to, overlap, norot) children();
  }
}

diff("hole") ubracket(
  diameter,
  width=width,
  ear_length=ear_length,
  thickness=thickness,
  chamfer=chamfer
) {
  screw_length = 5*thickness;
  attach_copies(["left_tab", "right_tab"], BOTTOM, overlap = screw_length)
  tag("hole")
    screw_hole(spec = screw, head = screw_head, thread = false, length = screw_length + $eps);
}
