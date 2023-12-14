include <../BOSL2/std.scad>

$eps = 0.1;
$fa = 4;
$fs = 0.2;

/// original measures in inches
// tower_outer_diameter = 3.170 * 25.4;
// tower_inner_diameter = 2.999 * 25.4;

/// converted
// tower_outer_diameter = 80.518;
tower_inner_diameter = 76.1746;

/// actual remeasure in mm
tower_outer_diameter = 80.67;

wall_thickness = 4;
tolerance = 1.2;

inner_diameter = tower_outer_diameter + tolerance;
outer_diameter = inner_diameter + wall_thickness;

height = (outer_diameter / 2) * 3 / 5;
inner_height = height - wall_thickness;

tower_height = height * 3;

% down(tower_height / 2) up(height / 2 - wall_thickness) diff("hollow")
        cyl(tower_height, tower_outer_diameter / 2) {
  tag("hollow") attach(BOTTOM, TOP, overlap = tower_height + $eps)
      cyl(tower_height + 2 * $eps, tower_inner_diameter / 2);
};

diff("hollow", "bump")
    cyl(height, outer_diameter / 2, rounding1 = wall_thickness / 4,
        chamfer2 = wall_thickness / 2) {
  tag("hollow") attach(BOTTOM, TOP, overlap = inner_height) cyl(
      inner_height + $eps, inner_diameter / 2, rounding2 = wall_thickness / 4);

  bump_size = wall_thickness / 5;
  tag("bump") zrot_copies(n = 5) down(wall_thickness / 2)
      fwd(inner_diameter / 2)
#cyl(inner_height - wall_thickness, bump_size, rounding = bump_size);
};
