include <BOSL2/std.scad>
include <BOSL2/threading.scad>

// Overall height of the cap.
height = 14;

// Height of the internal cavity.
inner_h = 12;

// Outer cap diameter.
outer_d = 54;

// Edge chamfer for the cap top/bottom edge.
chamfer = 1;

// Inner cap diameter.
inner_d = 52;

// Distance between threads.
thread_pitch = 2.6;

// Optional grip notch diameter; set 0 to disable grip notches.
grip = 1;

// Optional grip notch spacing around the outer_d circumference; set 0 to disable grip notches.
grip_every = 5;

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustment value for cutouts
$eps = 0.01;

diff(remove="thread grip") cyl(
  d = outer_d,
  h = height,
  chamfer = chamfer,
  orient = DOWN)  {

  if (grip * grip_every > 0) {
    tag("grip")
    zrot_copies(n=floor((outer_d - grip)*PI / grip_every))
    attach(LEFT, RIGHT, overlap=grip/2)
      cyl(d=grip, h = height + 2*$eps);
  }

  tag("thread")
  attach(BOTTOM, TOP, overlap=inner_h)
    threaded_rod(
      d = inner_d,
      h = inner_h + $eps,
      pitch = thread_pitch);

}
