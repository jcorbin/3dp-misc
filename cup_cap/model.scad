include <../BOSL2/std.scad>

$eps = 0.1;
$fa = 4;
$fs = 0.2;

target_id = 29;
target_od = 33.5;

wall_thickness = 4;
tolerance = 1.2;

inner_diameter = target_od + tolerance;
outer_diameter = inner_diameter + wall_thickness;

height = (outer_diameter / 2) * 3 / 5;
inner_height = height - wall_thickness;

tower_height = height * 3;

%down(tower_height / 2)
up(height / 2 - wall_thickness)
diff("hollow") cyl(
  tower_height,
  d=target_od
) {
  tag("hollow")
    attach(BOTTOM, TOP, overlap = tower_height + $eps)
    cyl(
      tower_height + 2 * $eps,
      d=target_id
    );
};

diff("hollow", "bump") cyl(
  height,
  d=outer_diameter,
  rounding1=wall_thickness / 4,
  chamfer2 = wall_thickness / 2
) {

  bump_size = wall_thickness / 5;

  tag("hollow")
    attach(BOTTOM, TOP, overlap = inner_height)
    cyl(
      inner_height + $eps,
      d=inner_diameter,
      rounding2=wall_thickness / 4
    );

  tag("bump")
    zrot_copies(n = 5)
    down(wall_thickness / 2)
    fwd(inner_diameter / 2)
    cyl(
      inner_height - wall_thickness,
      r=bump_size,
      rounding=bump_size
    );
};
