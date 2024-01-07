include <BOSL2/std.scad>

/* [Mode] */

mode = 2;

/* [Held Item Metrics] */

item_size = [ 200, 200, 4 ];

/* [Case Metrics] */

// Depth of the held item cutout(s) item height diameter
slot_depth = 55; // [10:1:90]

// Tolerance to allow where the case meets the held item(s)
case_tol = 0.2;

// Fillet rounding radius for the case
case_rounding = 2;

// XYZ padding for the case
case_padding = [ 2.5, 2.5, 2 ];

/* [Slide Cover Metrics] */

// Tolerance to allow where the slide cover meets the case
cover_tol = 0.2; // 0.1

// Fillet rounding radius for the slide cover
cover_rounding = 2;

// XZ padding for the slide cover
cover_padding = [ 2.5, 2.5 ];

/* [Geometry Detail] */

// Fragment minimum angle
$fa = 4; // 1

// Fragment minimum size
$fs = 0.2; // 0.05

// Epsilon adjustement value for gemoetry maths
$eps = 0.1;

/// implementation

if (mode == 1) {
  up(case_size()[2]/2)
    case();
} else if (mode == 2) {
  up(cover_size()[2]/2)
    cover();
} else if (mode == 3) {
  left(case_size()[0]/2 + 5)
  up(case_size()[2]/2)
    case();
  right(cover_size()[0]/2 + 5)
  up(cover_size()[2]/2)
    cover();
}

function payload_size() = item_size + [
  2 * case_tol,
  2 * case_tol,
  2 * case_tol,
];

module payload(extra = 0, anchor = CENTER, spin = 0, orient = UP) {
  size = payload_size() + [0, extra, 0];
  attachable(size = size, anchor = anchor, spin = spin, orient = orient) {
    cuboid(size = size, rounding = case_tol);

    // TODO support other modes like loaded model, repeated primitives

    /*
    left(100)
    fwd(100)
    down(2)

    right(67.055)
    back(65.912)
    down(1)
    import("/home/jcorbin/Downloads/Impossible Puzzle.stl");
    */

    children();
  }
}

module case(anchor = CENTER, spin = 0, orient = UP) {
  size = case_size();
  attachable(size = size, anchor = anchor, spin = spin, orient = orient) {
  overlap = payload_size()[2] * (slot_depth/100);

  tag_scope("case") diff(remove="payload")
    cuboid(size = size, rounding = case_rounding) {
      tag("payload") attach(TOP, BOTTOM, overlap=overlap) payload();
    };

    children();
  }
}

function case_size() = [
  payload_size()[0] + 2 * case_padding[0],
  payload_size()[1] + 2 * case_padding[1],
  payload_size()[2] * slot_depth/100 + case_padding[2],
];

module cover(anchor = CENTER, spin = 0, orient = UP) {
  size = cover_size();
  attachable(size = size, anchor = anchor, spin = spin, orient = orient) {
  overlap = payload_size()[2] * (1 - slot_depth/100);

  tag_scope("cover") diff(remove="payload slide")
    cuboid(size = size, rounding = cover_rounding) {
      slide_size = [
        case_size()[0],
        size[1] + 2 * $eps,
        case_size()[2],
      ];

      tag("payload") attach(TOP, TOP, overlap=overlap + slide_size[2])
        payload(extra = slide_size[1] - payload_size()[1]);

      tag("slide")
        attach(TOP, BOTTOM, overlap=slide_size[2] - $eps)
        cuboid(size = slide_size, rounding = case_rounding, edges = "Y");

    };

    children();
  }
}

function cover_size() = case_size() + [
  2 * (cover_tol + cover_padding[0]),
  2 * cover_tol,
  cover_tol + cover_padding[1] + payload_size()[2] * (1 - slot_depth/100),
];
