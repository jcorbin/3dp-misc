include <BOSL2/std.scad>;

/***

A D-shaped standoff that a curtain rod passes through, flat face to the wall,
holding the rod out far enough for the curtain to hang past whatever is under
it (trim, a blind, a return).

Printed profile-up: the D lies in XY and extrudes `thickness` in Z, so the rod
bore is a vertical hole -- no bridging, no supports -- and the layers stack
across the load path rather than along it. The rod pushes the nose outward and
the foot pushes the wall back; both of those are in-plane, which is the strong
way around for an FDM part.

# TODO

- feature: split it, so it can go on a rod that is already hung. As drawn it
  has to thread on over an end, which means taking the rod down and pulling a
  finial. A keyhole slot or a two-piece clamshell would fix that, and the hole
  is loose enough (5mm) that a slot would not have to flex far.
- feature: something to keep it from rotating on the rod. Nothing here fixes
  its clock angle; it stays put by friction against the wall and by the
  curtain's own weight, which is fine for a light rod and a guess for anything
  heavier.

*/

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudge to avoid coincident face flicker when differencing.
$eps = 0.01;

/* [Fitment and Quality] */

// Minimum feature size, more or less nozzle size.
feature = 0.4;

// Generic chamfer for bed interface and outside edges.
chamfer = 1.5;

/* [Part-iculars] */

// Curtain rod diameter.
rod_d = 20;

// Slop in the bore, so the rod passes loosely rather than gripping.
rod_tolerance = 5;

// Clear gap held between rod and wall, worst case.
standoff = 40;

// Depth along the rod's axis; how wide a band of rod this bears on.
thickness = 20;

// Material between the bore and the outside of the nose.
wall = 4;

// Extra width at the wall end, per side, past the nose.
foot_flare = 0;

// Corner rounding where the wall face turns into the sides.
foot_rounding = 3;

// Echo a fit report when rendering.
spacer_report = true;

/* [Part Selection] */

mode = 1; // [0:Assembly, 1:Spacer]

module __customizer_limit__() {}

/// derived geometry
//
// Spacer axes, matching the part as drawn:
// - X is across the D, symmetric about the rod
// - Y is out from the wall, which is the flat face at -Y
// - Z is along the rod, which is the print's build direction
//
// What the customizer parameters are short for, since their labels have to be
// one line apiece:
//
// - rod_tolerance is not a fit tolerance. It is a whole 5mm of slop, asked for:
//   the rod passes through loosely so the spacer can slide along it and find its
//   own place, rather than being gripped where it went on. Half of it comes
//   straight back out of the standoff -- see rod_center_y().
// - wall is the whole of what carries the rod's load down into the foot, so it
//   is deliberately past cosmetic: 4 is ten nozzle widths of material, which at
//   four perimeters a side leaves solid infill between them rather than a void.
// - foot_flare at 0 draws the sides as straight tangents from nose to foot,
//   which is the plain D. Flaring widens the wall contact -- more bearing area,
//   more resistance to the thing pivoting on the rod -- and widens the
//   footprint on the bed by the same amount.

// Bore diameter: the rod plus the slop asked for.
function rod_hole_d() = rod_d + rod_tolerance;

// Rod center measured out from the flat wall face.
//
// This is where the loose hole is paid for. A rod centered at standoff + rod_d/2
// only holds the gap when it is centered, and nothing centers it -- it is free
// to lie against the wall side of a hole that is rod_tolerance wider than it is,
// which eats half of that slop out of the gap. So the center goes out by the
// other half too, and `standoff` is then the worst case rather than the best.
function rod_center_y() = standoff + rod_d / 2 + rod_tolerance / 2;

// Outer radius of the nose wrapping the bore.
function nose_r() = rod_hole_d() / 2 + wall;

// Overall bounding size, [width, depth, thickness].
function spacer_size() = [
  2 * (nose_r() + foot_flare),
  rod_center_y() + nose_r(),
  thickness,
];

// Echo what the drawn part comes out at.
//
// The standoff is not checked, because it cannot fail: rod_center_y() is
// defined from it, so a comparison would only be arithmetic agreeing with
// itself. What is worth printing is the pair of gaps the loose bore leaves --
// they are the whole reason the nose sits where it does -- and the wall contact,
// which is the one number that moves when foot_flare or foot_rounding do.
module spacer_fit() {
  size = spacer_size();
  centered = rod_center_y() - rod_d / 2;
  against = centered - rod_tolerance / 2;
  contact = size.x - 2 * foot_rounding;
  echo(str("spacer fit: ", size,
      " -> width ", size.x, ", depth ", size.y, ", thickness ", size.z));
  echo(str("spacer fit: rod ", rod_d, " through a ", rod_hole_d(), " bore",
      ", centered ", rod_center_y(), " off the wall"));
  echo(str("spacer fit: gap ", against, " with the rod against the wall side",
      ", ", centered, " centered"));
  echo(str("spacer fit: wall contact ", contact, " x ", thickness,
      contact > 0 ? "" : " -- FAIL, foot_rounding has eaten the flat"));
}

/// the part

// The spacer itself.
//
// The outline is a hull of three chamfered cylinders -- the nose around the
// bore and one at each foot corner -- rather than a circle cut by a chord.
// A chord would only give a D if the flat fell inside the circle, and here the
// flat is 52.5 out from a nose of radius 16.5, so the bowl of the D is drawn on
// tangents down to the foot instead. Hulling chamfered prisms keeps the chamfer:
// every horizontal section interpolates between the two ends, so the result is
// the hulled profile extruded with the same break at top and bottom.
//
// The bore is cut last and flared at both ends, which is a lead-in for
// threading the rod through rather than decoration -- it is the only edge on
// the part that anything has to slide past.
module curtain_rod_spacer(anchor = CENTER, spin = 0, orient = UP) {
  size = spacer_size();
  r = nose_r();

  // the nose center in the bbox-centered frame
  nose_y = -size.y / 2 + rod_center_y();

  // foot corners, tangent to both the wall face and the sides
  foot_y = -size.y / 2 + foot_rounding;
  foot_x = size.x / 2 - foot_rounding;

  if (spacer_report) spacer_fit();

  attachable(
    anchor, spin, orient, size=size,
    anchors=[
      named_anchor("rod", [0, nose_y, 0], UP),
      named_anchor("wall", [0, -size.y / 2, 0], FRONT),
    ],
  ) {
    diff() {
      hull() {
        back(nose_y)
          cyl(r=r, h=thickness, chamfer=chamfer);
        xflip_copy()
        translate([foot_x, foot_y, 0])
          cyl(r=foot_rounding, h=thickness, chamfer=min(chamfer, foot_rounding - feature));
      }

      tag("remove")
      back(nose_y)
        cyl(d=rod_hole_d(), h=thickness + 2 * $eps, chamfer=-chamfer / 2);
    }

    children();
  }
}

/// dispatch / integration

//@make -o curtain_rod_spacer.stl -D mode=1

module main() {
  if (mode == 0) {
    assembly();
  } else if (mode == 1) {
    curtain_rod_spacer();
  }
}

// The spacer with the two things it sits between, ghosted: the rod through its
// bore, lying where it lies worst -- against the wall side of the hole -- and
// the wall its foot bears on.
module assembly() {
  size = spacer_size();
  slip = rod_tolerance / 2;

  curtain_rod_spacer() {
    %attach("rod", BOTTOM, overlap=thickness / 2)
      fwd(slip)
        cyl(d=rod_d, h=3 * thickness);

    %attach("wall", BACK)
      cuboid([3 * size.x, 2, 3 * thickness]);
  }
}

main();
