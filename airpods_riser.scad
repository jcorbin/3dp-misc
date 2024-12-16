include <BOSL2/std.scad>;
include <BOSL2/rounding.scad>
include <BOSL2/walls.scad>

use <grid2.scad>

/* [Body dimension] */

// Platform size in grid units.
platform_size = [ 2, 2, 6 ];

/* [Airpod dimension] */

airpod_size = [ 61, 31, 22.25 ];

airpod_round = 11;

channel_length = 42 - airpod_size.y + 42/2 - 20/2;

/* [Designed Supports] */

// Interface gap between support and supported part.
support_gap = 0.2;

// Bridging gap between supports.
support_every = 15;

// Thickness of support walls and internal struts.
support_width = 0.8;

// Thickness of footer support walls that run parallel to and underneath floating external walls.
support_wall_width = 2.4;

// Enable to show support walls in preview, otherwise only active in production renders.
$support_preview = true;

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/// dispatch / integration

module __customizer_limit__() {}

function scalar_vec2(v, dflt) =
  is_undef(v)? undef :
  is_list(v)? [for (i=[0:1]) default(v[i], default(dflt, 0))] :
  !is_undef(dflt)? [v,dflt] : [v,v];

module if_support() {
  if (!$preview || $support_preview) {
    children();
  }
}

module support_wall(
  h, l,
  gap = support_gap,
  width = support_width,
  anchor = CENTER, spin = 0, orient = UP
) {
  wid = scalar_vec2(width);
  if_support()
  tag("support")
  attachable(anchor, spin, orient, size=[wid.x, l, h]) {
    sparse_wall(
      h=h - 2*gap,
      l=l - 2*gap,
      thick=wid.x,
      strut=wid.y);

    children();
  }
}

/* Distributes sparse support walls within a cubic volume.
 *
 * gap specifies interface gap around all 6 faces of the cube, and may be:
 * - a single number to use constant gap around
 * - a 3-list specifying x/y/x gap values
 * - further within the 3-list, each entry maybe a pair of negative/positive gap values
 * 
 * every specifies an upper bound on wall spacing along the Y axis:
 * - walls will be spaced at most this far apart between starting/ending Y gap offsets
 * - the actual spacing will be adjusted down to evenly distribute size.y after gap
 */
module support_walls(
  size,
  gap = support_gap,
  every = support_every,
  width = support_width,
  wall_width = support_wall_width,
  anchor = CENTER, spin = 0, orient = UP
) {
  if_support()
  tag("support")
  attachable(anchor, spin, orient, size=size) {
    wid = scalar_vec2(width);

    xgap = scalar_vec2(is_list(gap) ? gap[0] : gap);
    ygap = scalar_vec2(is_list(gap) ? gap[1] : gap);
    zgap = scalar_vec2(is_list(gap) ? gap[2] : gap);
    pre_gap = [xgap[0], ygap[0], zgap[0]];
    post_gap = [xgap[1], ygap[1], zgap[1]];
    foot_gap = max(zgap);

    isize = size - pre_gap - post_gap;

    first_at = wid.x/2;
    last_at = isize.y - wid.x/2;
    at_span = last_at - first_at;
    at_space = at_span / ceil(at_span / every);
    nominal_at = [
      for (y = [ each [first_at : at_space : last_at], last_at ])
      y - isize.y/2
    ];

    xfoot = [
      pre_gap.x == 0 ? wall_width : 0,
      post_gap.x == 0 ? wall_width : 0
    ];
    yfoot = [
      pre_gap.y == 0 ? wall_width : wid.x,
      post_gap.y == 0 ? wall_width : wid.x
    ];

    xthick = flatten([
      xfoot[0] > 0 ? xfoot[0] : [],
      xfoot[1] > 0 ? xfoot[1] : []
    ]);
    ythick = [
      yfoot[0],
      each(repeat(wid.x, len(nominal_at) - 2)),
      yfoot[1]
    ];

    actual_at_x = flatten([
      xfoot[0] > 0 ? -(isize.x - wall_width)/2 : [],
      xfoot[1] > 0 ? (isize.x - wall_width)/2 : []
    ]);
    actual_at_y = [for (i=idx(nominal_at))
      nominal_at[i]
      + (i == 0 ? 1 : -1)
      * (ythick[i] - wid.x)/2
    ];

    translate((pre_gap - post_gap)/2) {

      if (len(actual_at_y) > 0)
      ycopies(spacing=actual_at_y)
      right(xfoot[0] > 0 ? (xfoot[0] - $eps)/2 : 0)
      left(xfoot[1] > 0 ? (xfoot[1] - $eps)/2 : 0)
        support_wall(
          h = isize.z,
          l = isize.x
            - (xfoot[0] > 0 ? xfoot[0] + $eps : 0)
            - (xfoot[1] > 0 ? xfoot[1] + $eps : 0)
            ,
          gap = 0,
          spin = 90,
          width = [ythick[$idx], wid.y]);

      if (len(actual_at_x) > 0)
      xcopies(spacing=actual_at_x)
        support_wall(
          h = isize.z,
          l = size.y - 2*foot_gap,
          gap = 0,
          width = [xthick[$idx], wid.y]);

    }

    children();
  }
}


module block(anchor = CENTER, spin = 0, orient = UP) {
  // TODO stacking lip top

  tag_scope("block")
  diff(keep="support") grid_platform(
    platform_size.x, platform_size.y, platform_size.z,
    anchor=anchor, spin=spin, orient=orient) {

    stack_h = struct_val(grid_stack(), "height");
    tag("remove")
    attach(TOP, BOTTOM, overlap=stack_h)
      grid_copies(spacing=42 /* grid_unit */, n=[platform_size.x, platform_size.y])
      grid_stack() {
        magnet_spacing = struct_val(grid_profile(grid_stack()), "magnet_spacing");

        tag("remove")
          grid_copies(spacing = magnet_spacing, n=[2, 2])
          attach(BOTTOM, TOP, overlap=$eps)
          cyl(d=6.5, h=2+$eps);

      }

    tag("remove")
      grid_copies(spacing=42 /* grid_unit */, n=[platform_size.x, platform_size.y])
      cuboid([20, 20, $parent_size.z + 2*$eps], rounding=5, edges="Z");

    tag("remove")
    // #up(63)
      attach(FRONT, BACK, overlap=airpod_size.y)
      cuboid(
        airpod_size + [0, $eps, 0],
        rounding = airpod_round,
        edges = [
          [0, 1, 0, 1], // yz -- +- -+ ++
          [1, 1, 1, 1], // xz
          [0, 0, 1, 1], // xy
        ]) {
          fwd(airpod_round/2)
          xcopies(spacing=19, n=2)
          support_wall(airpod_size.z, airpod_size.y - airpod_round, width=1.4);

          attach(BACK, FRONT, overlap=2)
          cuboid([16, channel_length + 2 + 6, 10], rounding=5, edges="Y")
            attach(BACK, FRONT, overlap=6)
            cuboid([42, 20, 10], rounding=5, edges="X");

        }

  }

  children();

}

block()
{
  // %show_anchors();
  // #cube($parent_size, center=true);
}

// diff() block() {
//   // TODO carve out airpod slot
//   // TODO allowance for charging cable?
// }
