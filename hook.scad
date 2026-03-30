include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>;
include <BOSL2/screws.scad>;
include <BOSL2/walls.scad>;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [Part Parameters] */

// General fit tolerance.
tolerance = 0.4;

// Minimum feature size, more or less nozzle size.
feature = 0.4;

// Generic chamfer for things like bed interface and outside non-interface edges.
chamfer = 1.5;

// Generic rounding for anonymous edges.
rounding = 1.5;

/* [Part-iculars] */

// measurements
// - flat top 18.2
// - span 24
// - front height 18.8
// - rear height 10

// Size of the C-shaped mounting hook, X is span front-to-back, Y is height of the C's "legs".
//
// # Round 1 prototypes:
//   1. mount_size = [50, 30];
//   2. mount_size = [55, 30];
//   3. mount_size = [50, 35];
//   4. mount_size = [55, 35];
// > ahh okay so what I'm seeing:
// > - the height of 4, but front-to-back dimension needs to be about half way between 3 & 4, gotcha
mount_size = [ 52.5, 35 ]; // Round 2 after feeedback

// Travel length between the C-shape mount hook and the curved loop.
travel = 50;

// Angle of travel to create an offset between mount hook and loop.
travel_ang = 30;

// Radius of the end loop.
loop_r = 25;

// Arc-angle of the end loop.
loop_ang = 210;

// Extrusion width of the hook; i.e. how many layers wide will be the hook.
hook_width = 26;

hole = 12;
hole_r = 1;

// Wall thickness of the from inner profile to outer profile.
wall = 3.0;

// Grip bump size in X.
grip_size = 5;

// Outer grip bump Y displacement.
grip_at = 2;

/// dispatch / integration

function hook_profile() = let (
  mount_span = mount_size.x + 2*tolerance,
  path = turtle([
    "turn", -90,
    "arcleft", loop_r, loop_ang -travel_ang,
    "move", travel,
    "turn", travel_ang,
    "move", mount_size.y,
    "turn", -90,
    "move", mount_span,
    "turn", -90,
    "move", mount_size.y - grip_at + wall/2,
    "turn", -90,
    "move", grip_size + wall/2,
  ]),
  bnds = pointlist_bounds(path),
) rot(-loop_ang+180, p=move([
    (bnds[0].x - bnds[1].x)/2,
    mount_size.y + (bnds[0].y - bnds[1].y)/2,
  ], path));

prof = hook_profile();
inner = offset(prof, delta=-wall/2);
outer = offset(prof, delta=wall/2);
hook_shape = concat(inner, reverse(outer));

module dev() {
  echo(str("prof", prof));
  color("red") stroke(prof, width=feature);
  color("blue") stroke(outer, width=feature);
  color("green") stroke(inner, width=feature);
  // color("blue") polygon(hook_shape);
}

module main() {
  difference() {

    union() {
      linear_sweep(hook_shape, hook_width);
      move(prof[len(prof)-5])
      left(wall/2 - $eps)
      up(hook_width/2)
      prismoid(
        anchor=BOTTOM,
        orient=RIGHT,
        spin=90,
        size2=[wall, hook_width],
        size1=[2*wall, hook_width],
        h=grip_size + wall,
        shift=[wall/2, 0],
      );
    }

    if (hole > 0) {
      up(hook_width/2)
      move(prof[len(prof)-6 - 30])
      yrot(45)
      cuboid([hole, 4*wall, hole], rounding=hole_r, edges="Y");
    }

  }
}

main();
// dev();
