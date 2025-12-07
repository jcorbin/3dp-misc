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
mount_size = [23, 21];

// Travel length between the C-shape mount hook and the curved loop.
travel = 25;

// Angle of travel to create an offset between mount hook and loop.
travel_ang = 30;

// Radius of the end loop.
loop_r = 15;

// Arc-angle of the end loop.
loop_ang = 210;

// Extrusion width of the hook; i.e. how many layers wide will be the hook.
hook_width = 3.5;

// Wall thickness of the from inner profile to outer profile.
wall = 2.0;

// Grip bump size in X.
grip_size = 3;

// Outer grip bump Y displacement.
grip_at = 9;

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
}

main();
// dev();
