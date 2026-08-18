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

Three parts:

1. the spacer, in whatever the rest of the house prints in
2. a boot, in TPU, that pulls onto the spacer's foot and is what actually
   touches the wall -- so the thing bearing on paint is soft, and the spacer's
   printed corner is not
3. a liner, in TPU, a split sleeve that snaps onto the rod for the spacer to
   slide over -- it fills the 5mm the bore was asked to leave, so the rod stops
   rattling in it and the assembly stops wandering along it

The boot's outside is a prismoid flaring out toward the wall, which spreads the
load over a wider pad than the spacer's own 27 x 20 of contact and gives it a
draft angle to print up: widest face on the bed, every wall leaning inward,
nothing overhanging. Inside it is a plain socket over the foot with a few
horizontal fins standing into it -- see boot_fin().

# As built

Two printed and hung 2026-08-16: PETG spacers with TPU boots, over a door on a
20mm rod. Sits square, gap reads as the two rod diameters it should be, and the
boot does not announce itself as a separate part. What follows is what only
became visible once one was in place carrying something.

- It is a strut, not a bracket. Nothing here pushes a rigid rod anywhere; the
  gap holds only while something else presses the rod back toward the wall.
  Unloaded, the spacer's own mass hangs 52.5 out from the rod axis and wants to
  swing the foot straight down, and nothing fixes its clock angle -- so this is
  a part that works because it is loaded, not one that works and then gets
  loaded.
- What margin there is comes from the pad being nearly as wide as the arm is
  long: 21.7 of half-width against a 52.5 arm, so the load resultant has about
  22 degrees of clocking to play with before it walks off the edge of the pad
  and the boot is standing on a corner. That flat pad is the anti-rotation
  feature, such as it is; there is no other.
- The 5mm of bore slop is also 14 degrees of skew -- 5 diametral over a 20 bore
  -- and the wall wins that argument. The pad stays flat and the rod takes up
  the slack instead, so the bore bears on its two mouth chamfers rather than
  across its full 20. Harmless on a light rod, and those chamfers are the
  relieved edge anyway, but the same slop leaves nothing holding the spacer
  anywhere along the rod. This is what the liner is for, and it is the one
  fix here that retrofits onto parts already hung.
- A 33 nose is a 33 obstruction: curtain rings cannot pass it. Fine at the
  ends, where these went; it rules the part out mid-span.
- TPU held against latex paint under steady pressure is the thing to check back
  on. It will burnish a mark or collect dust into a ring long before it fails
  at anything structural, and the boot made that more likely rather than less.

# TODO

- feature: split it, so it can go on a rod that is already hung. As drawn it
  has to thread on over an end, which means taking the rod down and pulling a
  finial -- twice, so far. The slot belongs on the crown at +Y, the side the
  load pushes the rod away from and the only part of the ring carrying nothing.
  But 4mm of PETG will not spring 20 open, so it is a two-piece or a captured
  cap rather than the snap that the liner gets to be.
- unknown: whether the boot needs venting. Its socket is closed at the pad, so
  pushing the spacer in compresses what is in there, and only the fins' own
  leakage lets it out. If it turns out to fight going on or to creep back off,
  the answer is a small hole through the pad -- but that is a hole in the face
  that touches the wall, so it waits for a print that actually misbehaves.
  Nothing observed either way on the two that went up.

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

// Echo a fit report for whichever parts get rendered.
report = true;

/* [Boot] */

// Skirt thickness around the boot's socket.
boot_wall = 2;

// How far up the spacer's foot the boot reaches.
boot_depth = 12;

// Thickness of the pad the wall bears on.
boot_base = 2;

// How far the boot flares out toward the wall, per side.
boot_taper = 3;

// Slip clearance between socket and spacer, before the fins.
boot_tolerance = 0.2;

// Corner rounding on the boot's outside.
boot_rounding = 3;

// Number of grip fins inside the boot.
fin_n = 4;

// How far a fin stands into the socket.
fin_reach = 0.6;

// Height of a fin's lead-in ramp.
fin_ramp = 1.6;

/* [Liner] */

// Interference on the rod, so the sleeve stretches on rather than dropping on.
liner_grip = 0.4;

// Interference in the spacer's bore, so the sleeve stays with the spacer.
liner_squeeze = 0.2;

// Mouth width; under the rod diameter is what makes it snap on.
liner_mouth = 14;

// Collar width past the bore, the stop the spacer slides up to.
liner_collar = 2;

// Collar thickness.
liner_collar_h = 2;

/* [Part Selection] */

mode = 1; // [0:Assembly, 1:Spacer, 2:Boot, 3:Liner, 100:Boot Section]

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

  if (report) spacer_fit();

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

/// boot
//
// Boot axes, which are not the spacer's: Z is out from the wall, so the part
// stands the way it prints and the way prismoid() and the fin stack are drawn.
// The wall pad is at -Z and the mouth the spacer enters is at +Z. The socket's
// X is the spacer's width and its Y is the spacer's thickness -- placing it
// against the spacer's "wall" anchor is what swaps those back.
//
// What the customizer labels are short for:
//
// - boot_depth is how much of the spacer's 69mm of depth the socket swallows.
//   Enough to hold square and to give the fins somewhere to sit; not so much
//   that it starts covering the part of the D anyone looks at.
// - boot_tolerance is a slip fit on purpose. The socket alone is meant to go on
//   by hand, and gripping is the fins' job -- a cavity sized to interfere over
//   its whole 12mm would have to be forced on, and TPU that far oversized
//   simply rolls up at the mouth instead of seating.
// - fin_reach is measured from the socket wall, so what the spacer actually
//   sees is fin_reach less boot_tolerance: 0.4 a side, on four fins.

// Socket cross-section, [x, y], read off the spacer so the two cannot disagree.
//
// The spacer is a constant section here: its sides run parallel from the foot's
// rounding up to the nose, so anything in the first foot_rounding..rod_center_y
// of it is the same 33 x 20 with the same chamfer. Only the last 3mm before the
// wall face rounds in, and the socket does not chase that -- it leaves the
// boot's own corners a little air there rather than a feather edge.
function boot_socket() = [spacer_size().x, thickness] + 2 * [boot_tolerance, boot_tolerance];

// Outer cross-section at the mouth, where the skirt is thinnest.
function boot_mouth() = boot_socket() + 2 * [boot_wall, boot_wall];

// Overall bounding size, [width, depth, height]; the wall pad is the widest of it.
function boot_size() = [
  boot_mouth().x + 2 * boot_taper,
  boot_mouth().y + 2 * boot_taper,
  boot_base + boot_depth,
];

// One grip fin: a ring standing fin_reach into the socket.
//
// Asymmetric, and pointed the way it has to go on. Its underside is a flat step
// facing the pad, and above that it feathers back out to the socket wall, so
// the spacer meets a ramp going in and a square edge coming out. Going in, each
// fin is a short squeeze that relaxes as soon as the section passes; coming out,
// the same edge folds under itself rather than sliding.
//
// Fins rather than an undersized socket because the interference is the same
// either way but the insertion force is not: four thin ridges deflect, where a
// 12mm-long press fit has to compress over its whole length. It also puts the
// grip somewhere specific rather than spreading it over a face that is never
// flat anyway, printed.
module boot_fin(cav, reach, h) {
  difference() {
    cuboid([cav.x, cav.y, h] + 2 * [$eps, $eps, 0],
      chamfer=chamfer, edges="Z", anchor=BOTTOM);

    // Ends wider than the fin it is cutting, so the feather edge lands just shy
    // of the top rather than exactly on it, leaving nothing zero-thick behind.
    down($eps)
      prismoid(
        size1=cav - 2 * [reach, reach],
        size2=cav + 4 * [$eps, $eps],
        h=h + 2 * $eps, chamfer=chamfer, anchor=BOTTOM);
  }
}

// The boot: a prismoid, socketed out from the mouth and finned inside.
//
// Print it as drawn, pad down, in TPU. Every outside face leans inward going up
// -- that is what boot_taper buys besides the wider pad -- and the socket is a
// vertical bore, so there is no overhang anywhere on it and no support to peel
// out of a flexible part.
//
// Order matters, the way it does in any part where features live inside a
// hollow: the prismoid is socketed first and the fins go on after, or the socket
// would take them with it.
module curtain_rod_boot(anchor = CENTER, spin = 0, orient = UP) {
  size = boot_size();
  cav = boot_socket();
  mouth = boot_mouth();

  // socket floor, and the fin spacing above it
  floor_z = -size.z / 2 + boot_base;
  step = boot_depth / (fin_n + 1);

  if (report) {
    echo(str("boot fit: ", size, " over a ", cav, " socket ", boot_depth, " deep"));
    echo(str("boot fit: ", fin_n, " fins every ", step,
        ", each ", fin_reach - boot_tolerance, " into the spacer",
        step > fin_ramp ? "" : " -- FAIL, the ramps overlap"));
  }

  attachable(
    anchor, spin, orient, size=size,
    anchors=[
      named_anchor("wall", [0, 0, -size.z / 2], DOWN),
    ],
  ) {
    union() {
      diff() {
        prismoid(size1=[size.x, size.y], size2=mouth, h=size.z,
          rounding=boot_rounding, anchor=CENTER);

        // socket, open at the mouth and floored boot_base above the pad
        tag("remove")
        up(floor_z)
          cuboid([cav.x, cav.y, boot_depth + $eps],
            chamfer=chamfer, edges="Z", anchor=BOTTOM);
      }

      // Fins up the socket, the first a step above the floor rather than on it:
      // the corner where floor meets wall is where a fin would be hardest to
      // print and least use, since the spacer bottoms out there anyway.
      if (fin_n > 0)
        for (i = [1:fin_n])
          up(floor_z + i * step)
            boot_fin(cav, fin_reach, fin_ramp);
    }

    children();
  }
}

/// liner
//
// Liner axes are the spacer's: Z is along the rod, and the mouth opens toward
// +Y. That orientation is the whole install note. The rod bears on the wall
// side of the bore, so the continuous back of the C goes there and the split
// goes on the crown -- the one part of the ring carrying nothing. Same argument
// as the split-spacer TODO, except here it costs nothing, because TPU will
// actually do what PETG cannot.
//
// It retrofits without taking anything down, which is the point: slide the
// spacer along the rod to clear a span, snap the liner on there, slide the
// spacer back over it until it stops on the collar. No finial comes off.
//
// With one in, the rod is centered rather than lying against the wall side of
// its 5mm, so the gap goes to the 42.5 that spacer_fit() reports as the
// centered case. The standoff is still specified worst-case; the liner just
// stops the part from ever being at its worst.
//
// What the customizer labels are short for:
//
// - liner_grip is interference on the rod, not clearance. The sleeve is drawn
//   under size and stretches on, and that grip is the whole of what keeps the
//   assembly from wandering along the rod.
// - liner_squeeze is the same idea pointed outward, into the spacer's bore. It
//   is small because the split already does most of that work: a C sprung open
//   around a rod is a spring pushing outward whether or not it was drawn to.
// - liner_mouth under rod_d is what makes it snap on rather than drop on. It
//   buys retention and costs insertion force, both off the same number.

// Echo what the sleeve comes out at.
//
// The number worth checking is the wrap, because it is the one that decides
// whether this stays on the rod at all, and it is not the number typed in:
// liner_mouth is measured straight across the flat, and what holds is the arc.
module liner_fit(id, od, collar_d, len) {
  wrap = liner_mouth < id ? 360 - 2 * asin(liner_mouth / id) : 0;
  echo(str("liner fit: ", id, " on a ", rod_d, " rod, ", od, " in a ",
      rod_hole_d(), " bore, ", collar_d, " collar"));
  echo(str("liner fit: mouth ", liner_mouth, " wraps ", wrap, " deg",
      wrap > 180 ? "" : " -- FAIL, it will not hold on the rod"));
  echo(str("liner fit: spreads ", rod_d - liner_mouth, " to pass the rod",
      ", ", len, " long over ", thickness, " of bore"));
}

// The split sleeve.
//
// Printed standing on its collar, which is both how it prints and how it works:
// the layers stack along the rod, so the arms spread within the layer plane
// rather than trying to peel one layer off the next, and the widest face is on
// the bed with nothing overhanging above it.
//
// The slot runs the whole height, collar included. A closed collar ring would
// have to stretch over the rod instead of spreading past it, which is the one
// thing an otherwise very forgiving material is not good at.
module curtain_rod_liner(anchor = CENTER, spin = 0, orient = UP) {
  id = rod_d - liner_grip;
  od = rod_hole_d() + liner_squeeze;
  collar_d = od + 2 * liner_collar;
  len = liner_collar_h + thickness;

  if (report) liner_fit(id, od, collar_d, len);

  attachable(
    anchor, spin, orient, d=collar_d, l=len,
    anchors=[
      named_anchor("collar", [0, 0, -len / 2], DOWN),
      named_anchor("mouth", [0, od / 2, 0], BACK),
    ],
  ) {
    diff() {
      union() {
        down(len / 2)
          cyl(d=collar_d, h=liner_collar_h,
            chamfer1=min(chamfer, liner_collar_h - feature), anchor=BOTTOM);

        // The sleeve, chamfered at the leading end only. That end meets the
        // spacer's own flared bore mouth, and two eased edges is what keeps
        // sliding the spacer on from rolling the sleeve up ahead of it.
        down(len / 2 - liner_collar_h)
          cyl(d=od, h=thickness,
            chamfer2=min(chamfer, (od - id) / 2 - feature), anchor=BOTTOM);
      }

      // The bore, flared both ends, so the sleeve leads onto the rod either way
      // up -- it is symmetric about that even though the outside is not.
      tag("remove")
        cyl(d=id, h=len + 2 * $eps, chamfer=-chamfer / 2);

      // The mouth, cut from the axis outward so its flanks stay parallel and
      // the rod passes straight through rather than having to round a corner
      // on the way in. Where those flanks meet the bore is the sharpest thing
      // on the part and the place a crack would start, if TPU cracked.
      tag("remove")
      back(collar_d / 4)
        cuboid([liner_mouth, collar_d / 2 + $eps, len + 2 * $eps]);
    }

    children();
  }
}

/// dispatch / integration

//@make -o curtain_rod_spacer.stl -D mode=1
//@make -o curtain_rod_boot.stl -D mode=2
//@make -o curtain_rod_liner.stl -D mode=3

module main() {
  if (mode == 0) {
    assembly();
  } else if (mode == 1) {
    curtain_rod_spacer();
  } else if (mode == 2) {
    curtain_rod_boot();
  } else if (mode == 3) {
    curtain_rod_liner();
  } else if (mode == 100) {
    // The boot cut down its length. Not a part -- it is the only way to see
    // what a fin's profile actually came out as, which is the one thing in
    // either part that is not measurable off the outside.
    back_half()
      curtain_rod_boot();
  }
}

// All three parts and the two things they sit between, the latter ghosted: the
// rod through the bore and the wall, which now bears on the boot rather than on
// the spacer.
//
// Drawn with the liner in, which means the rod is drawn centered. Without one
// it lies rod_tolerance/2 further toward the wall and the gap is the 40 that
// spacer_fit() calls the worst case -- that is the configuration the standoff
// is specified against, and the liner is what makes it stop happening.
module assembly() {
  size = spacer_size();

  curtain_rod_spacer() {
    %attach("rod", BOTTOM, overlap=thickness / 2)
      cyl(d=rod_d, h=3 * thickness);

    // The liner filling the bore, collar out the near end. Its mouth opens
    // toward +Y with no spin needed, which is the crown -- away from the wall,
    // off the side the rod loads.
    color("#707070ff")
    attach("rod", BOTTOM, overlap=thickness / 2 + liner_collar_h)
      curtain_rod_liner();

    // The boot pulled on over the foot: mouth into the spacer by the whole
    // socket depth, which lands its floor on the spacer's wall face.
    color("#404040ff")
    attach("wall", TOP, overlap=boot_depth)
      curtain_rod_boot();

    // The wall, held off by the boot's pad rather than touching the spacer.
    // Hung off the spacer's own anchor rather than the boot's, so it stays a
    // ghost -- inside a colored subtree the % modifier loses to the color.
    %attach("wall", BACK, overlap=-boot_base)
      cuboid([3 * size.x, 2, 3 * thickness]);
  }
}

main();
