include <BOSL2/std.scad>;

/* XXX layout notion
 * - Rd: reader on a 3x2 module
 * - Ho: holder on a 2x1 module
 * - Tw: swab stand is a 2x2 twizzle rack
 * - XX: swab discard bin in a 1x1 tall bin
 * - Fr: fresh swabs could dispense from a similar 1x1 tall bin
 *
 * |Fr|Ca|XX|Tw|Tw|
 * |Rd|Rd|Rd|Tw|Tw|
 * |Rd|Rd|Rd|Ho|Ho|
 *
 */

/* [Geometry Detail] */

// Fragment minimum angle.
$fa = 4; // 1

// Fragment minimum size.
$fs = 0.2; // 0.05

// Nudging value used when cutting out (differencing) solids, to avoid coincident face flicker.
$eps = 0.01;

/* [Reader Kit] */

// bounding cube of the reader.
reader_size = [ 91, 65, 101 ];

// bounding box of reader prism top.
reader_top_size = [ 80, 60 ];

// shift of the reader top box vs footprint.
reader_shift = [0, 2];

// rounding of the reader prism along the Z axis.
reader_rounding = 16;

// TODO model reader feet/lift?
// TODO locate reader back face ports: 1 DC barrel jack, 1 USB-C port
// TODO locate reader front face features: button, indicator LED(s)

// bounding box size of the test cared/vial holder.
holder_size = [ 68, 30, 23 ];

/* [Per Test Kit] */

// test card is a thin cuboid, with some spherical elaborations; this desribes the main card body, not the bounding box of its elaborations. TODO model its cap?
card_size = [ 42, 2.3, 61 ];

// test vial modeled as a cylinder; TODO model its cap?
vial_size = [ 14, 56 ];

// how deeply to set vial into its holder.
vial_holder_h = 23;

// TODO model swab, at least its stick

/// dispatch / integration

module __customizer_limit__() {}

// module XXX(anchor = CENTER, spin = 0, orient = UP) {
//   size = [XXX.x, XXX.z, XXX.y];
//   attachable(anchor, spin, orient, size=size) {
//     xrot(-90)
//     down(size.z/2)
//     back(size.y/2)
//     left(size.x/2)
//       import("XXX.stl");
//     children();
//   }
// }

// module XXX(anchor = CENTER, spin = 0, orient = UP) {
//   size = [XXX.x, XXX.z, XXX.y];
//   attachable(anchor, spin, orient, size=size) {
//     XXX();
//     children();
//   }
// }

module reader(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient,
    size=reader_size,
    size2=reader_top_size,
    shift=reader_shift
  ) {
    back(reader_shift.y/2)
    prismoid(
      size1=[reader_size.x, reader_size.y],
      size2=reader_top_size,
      h=reader_size.z,
      shift=reader_shift,
      rounding=reader_rounding,
      anchor=CENTER);

    // TODO model the front button
    // TODO model the front leds
    // TODO model the back barrel jack
    // TODO model the back usb-c port

    children();
  }
}

reader()
{
  // position(TOP) #sphere(1);
  %show_anchors();
  // #cube($parent_size, center=true);
}
