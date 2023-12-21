include <../BOSL2/std.scad>

/// geometry config

$eps = 0.1;
$fa = 4;
$fs = 0.2;

/// mode

fit_test = true;

/// settings

tolerance = 0.2;

span = 148;
lift = 77;
width = 200;
grip = [ 5, 10 ];
foot = [ 50, 20 ];

rounding = 5;

/// implementation

size = [
  fit_test ? 3 * rounding : width,
  span + 2 * (tolerance + grip[0]),
  lift + foot[1],
];

diff("span") cuboid(size, rounding = rounding, except_edges = BOTTOM) {

  tag("span") attach(TOP, TOP, overlap = grip[1])
      cube([ size[0] + 2 * $eps, span + 2 * tolerance, grip[1] + $eps ]);

  tag("foot") attach(BOTTOM, BOTTOM, norot = true)
      cuboid([ size[0], span + grip[0] + foot[0], foot[1] ],
             rounding = rounding, except_edges = BOTTOM) {

    /* TODO would be nice to chamfer that corner
    ycopies(spacing = [ -size[1] / 2, size[1] / 2 ])
    up(foot[1]/2)
    xrot(45)
    cuboid([ size[0] - 2* rounding, 2*rounding, 2*rounding ]);
    */

  };
};
