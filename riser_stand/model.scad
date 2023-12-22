include <../BOSL2/std.scad>

/// geometry config

$eps = 0.1;
$fa = 4;
$fs = 0.2;

/// mode

fit_test = false;

/// settings

tolerance = 0.2;

span = 148;
lift = 77;
width = 600 / 3 - 6;
grip = [ 5, 10 ];
foot = [ 50, 20 ];

rounding = 5;

/// implementation

size = [
  fit_test ? 3 * rounding : width,
  span + 2 * (tolerance + grip[0]),
  lift + foot[1],
];

zrot(90)
yrot(90)
diff("span") cuboid(size, rounding = rounding, edges = "X", except_edges = BOTTOM) {

  tag("span") attach(TOP, TOP, overlap = grip[1])
      cube([ size[0] + 2 * $eps, span + 2 * tolerance, grip[1] + $eps ]);

  tag("foot") attach(BOTTOM, BOTTOM, norot = true)
      cuboid([ size[0], span + grip[0] + foot[0], foot[1] ],
             rounding = rounding, edges = "X", except_edges = BOTTOM);

};
