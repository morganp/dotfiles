---
name: openscad-bosl2
description: >
  Generate and assist with 3D modeling code using the OpenSCAD language and BOSL2 library.
  Use this skill whenever the user asks to design a 3D part, model, enclosure, bracket,
  mechanical component, or anything that should be 3D printed or rendered as a CAD model.
  Also trigger when the user mentions OpenSCAD, BOSL2, .scad files, .3mf files, parametric design,
  3D printable parts, or asks for help with shapes, threads, gears, or other mechanical
  geometry in code. Even if the user just says "design me a box" or "I need a part that
  does X", this skill applies if the context is computational 3D modeling.
---

# OpenSCAD + BOSL2 Skill

You are an expert in OpenSCAD parametric 3D modeling using the BOSL2 library. Your job
is to generate correct, clean, printable OpenSCAD code that uses BOSL2 idioms throughout.

## Output expectations

- Produce complete, self-contained `.scad` files with all necessary `include` statements
- Save files to disk when the user wants to open them in OpenSCAD; otherwise show code inline
- Always add a brief comment block at the top describing what the part is and its key parameters
- Use parametric variables (not magic numbers) for anything the user might want to adjust
- Use `$fn = 64;` as the default -- this gives smooth circles for both development previews and
  final renders. Only drop to 32 if the file is very slow to preview.

## Core include pattern

```scad
include <BOSL2/std.scad>
// Add specialty includes only as needed:
include <BOSL2/threading.scad>   // threaded_rod, threaded_nut, acme_threaded_rod
include <BOSL2/gears.scad>       // spur_gear, bevel_gear, rack, worm, worm_gear
include <BOSL2/rounding.scad>    // round_corners, path_sweep, skin
```

`std.scad` covers shapes, attachments, distributors, beziers, paths, masks, and math.
Only add specialty files when the design actually needs them.

## Primitives -- always prefer BOSL2 over vanilla

| Task | Use this | Not this |
|------|----------|----------|
| Box | `cuboid([x,y,z])` | `cube([x,y,z])` |
| Cylinder | `cyl(h=h, d=d)` | `cylinder(h,r,r)` |
| Hollow tube | `tube(h=h, od=od, wall=w)` | manual difference |
| Sphere | `spheroid(r=r)` | `sphere(r)` |

BOSL2 primitives support `anchor`, `spin`, `orient`, `rounding`, and `chamfer` natively.
Vanilla primitives (`cube`, `cylinder`, `sphere`) still work but are not attachment-aware.

## The attachment system -- the most important BOSL2 concept

BOSL2 uses named anchor points on every shape. Direction constants are vectors you can add:
`TOP`, `BOTTOM`, `LEFT`, `RIGHT`, `FRONT`, `BACK`, `CENTER`
Corner example: `TOP+RIGHT+FRONT`

**anchor** -- which point of the object sits at the local origin
**attach(FROM, TO)** -- places a child's TO anchor against the parent's FROM anchor

```scad
// Cylinder growing upward from top of a box (attach() must be inside parent's { } block):
cuboid([30, 30, 10]) {
    attach(TOP, BOTTOM) cyl(h=15, d=10);
}
```

`attach()` ONLY works inside a parent object's `{ }` children block. It cannot be used
as a standalone statement in the top level or inside `diff()` siblings.

## Boolean operations -- use diff(), not difference()

BOSL2's `diff()` + `tag("remove")` is the idiomatic boolean subtraction system.

### CRITICAL RULE: where attach() can and cannot be used

`attach()` requires `$parent_geom` which is only available inside a parent object's children
block. Calling `attach()` as a sibling of the parent inside `diff()` will crash with
"No object to attach to!". There are two correct patterns -- use whichever fits the situation:

**Pattern A -- nest removals inside the parent's children block (enables attach):**
```scad
diff() {
    cuboid([40, 40, 20], anchor=BOTTOM) {
        tag("remove") attach(TOP) cyl(h=25, d=3.4);
        tag("remove") attach(TOP) cyl(h=4, d=6);   // counterbore
    }
}
```

**Pattern B -- siblings with explicit positioning, no attach() (simpler for most holes):**
```scad
// anchor=BOTTOM on removed shapes so they start at Z=0, same as the parent
diff() {
    cuboid([40, 40, 20], anchor=BOTTOM);
    tag("remove") cyl(h=22, d=3.4, anchor=BOTTOM);  // Z=0 to Z=22, drills through 20mm body
}
```

Never do this -- `attach()` as a sibling will crash:
```scad
// WRONG -- crashes with "No object to attach to!":
diff() {
    cuboid([40, 40, 20], anchor=BOTTOM);
    tag("remove") attach(TOP) cyl(h=25, d=3.4);  // attach() has no parent here
}
```

Use `intersect()` + `tag("intersect")` the same way for intersection.

## 3D printability rules -- always apply these

1. **`anchor=BOTTOM` on the top-level part** -- this places the part's bottom face at Z=0,
   sitting on the virtual build plate. Never leave a finished part floating or centered.

2. **Hole tolerance** -- add 0.2mm to hole diameters for clearance fits, 0.1mm for press fits.
   Define a constant: `CLEARANCE = 0.2;` and use `d = bolt_d + CLEARANCE`.

3. **Wall thickness** -- minimum 1.2mm (2x a standard 0.6mm nozzle) for structural walls.
   Use `tube(wall=...)` rather than manual subtraction.

4. **Rounding/chamfering** -- prefer `cuboid(rounding=r, edges=TOP)` or `cyl(chamfer=c)`
   over `minkowski()`, which is extremely slow.

5. **Subtract holes with extra depth** -- when drilling through with `diff()`, make the
   subtracted cylinder slightly taller (e.g., `h = part_h + 1`) so it cleanly pierces both faces.

## Common patterns

### Flat-bottomed enclosure with lid lip
```scad
include <BOSL2/std.scad>

$fn = 64;
WALL = 2;
W = 60; D = 40; H = 30;

// Pattern A: nest cavity inside parent's children block so attach() works
diff() {
    cuboid([W, D, H], anchor=BOTTOM, rounding=2, edges=TOP) {
        tag("remove") attach(TOP)
            cuboid([W - WALL*2, D - WALL*2, H - WALL + 1], anchor=TOP);
    }
}
```

### Bolt pattern grid
```scad
// Pattern B: siblings -- use anchor=BOTTOM on holes so they start at Z=0 and drill upward
diff() {
    cuboid([60, 40, 5], anchor=BOTTOM);
    tag("remove")
        grid_copies(spacing=[40, 20], n=[2, 2])
            cyl(h=7, d=3.4, anchor=BOTTOM);  // Z=0 to Z=7, drills through 5mm plate
}
```

### Nested attachment chain (additive, no diff needed)
```scad
cuboid([30, 30, 10], anchor=BOTTOM) {
    attach(TOP) {
        cyl(h=20, d=15) {
            attach(TOP) spheroid(d=15);
        }
    }
}
```

### Circular pattern of holes
```scad
// Pattern B: siblings -- anchor=BOTTOM aligns cylinder bottom with part bottom at Z=0
diff() {
    cyl(h=10, d=50, anchor=BOTTOM);
    tag("remove")
        zrot_copies(n=6, r=18)
            cyl(h=12, d=5, anchor=BOTTOM);  // Z=0 to Z=12, drills through 10mm disk
}
```

## Threading

```scad
include <BOSL2/std.scad>
include <BOSL2/threading.scad>

PITCH = 1.5;  // mm per thread
BOLT_D = 10;

// External (male) thread:
threaded_rod(d=BOLT_D, l=30, pitch=PITCH, bevel=true, anchor=BOTTOM);

// Internal (female) thread through a block -- Pattern B (siblings):
// anchor=BOTTOM on both means they both start at Z=0 and align naturally
diff() {
    cuboid([20, 20, 15], anchor=BOTTOM);
    tag("remove")
        threaded_rod(d=BOLT_D, l=16, pitch=PITCH, internal=true, bevel=true, anchor=BOTTOM);
}

// Cap with internal thread from bottom, closed top -- Pattern B (siblings):
HEIGHT = 12;  TOP_WALL = 3;  OD = 18;  THREAD_DEPTH = HEIGHT - TOP_WALL;
diff() {
    cyl(h=HEIGHT, d=OD, anchor=BOTTOM);
    tag("remove")
        // anchor=BOTTOM: thread sits at Z=0, goes up to THREAD_DEPTH+1, leaving top closed
        threaded_rod(d=BOLT_D, l=THREAD_DEPTH + 1, pitch=PITCH, internal=true, bevel=true, anchor=BOTTOM);
}
```

`internal=true` generates a slightly oversized hole shape for correct fit.
`bevel=true` chamfers the thread entry for easier starting.

## Gears

```scad
include <BOSL2/std.scad>
include <BOSL2/gears.scad>

MOD = 2;       // gear module (tooth size); larger = bigger teeth
TEETH_A = 20;
TEETH_B = 40;
THICKNESS = 8;
SHAFT_D = 5;

// Meshing spur gears (share the same mod):
spur_gear(mod=MOD, teeth=TEETH_A, thickness=THICKNESS, shaft_diam=SHAFT_D);
translate([gear_dist(mod=MOD, teeth1=TEETH_A, teeth2=TEETH_B), 0, 0])
    spur_gear(mod=MOD, teeth=TEETH_B, thickness=THICKNESS, shaft_diam=SHAFT_D);
```

Use `pitch=` (circular pitch in mm) as an alternative to `mod=`. All gears in a mesh must share the same value.

## Bezier sweeps and lofts

```scad
include <BOSL2/std.scad>

// Sweep a circular profile along an arc:
path = arc(r=30, angle=180);
path_sweep(circle(d=6), path);

// Loft (skin) between two profiles:
skin([
    circle(r=10),
    regular_ngon(n=6, r=10)
], z=[0, 20], slices=5, anchor=BOTTOM);
```

## Rounding 2D paths before extrusion

```scad
include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

pts = square(30, center=true);
rounded = round_corners(pts, radius=4);
linear_extrude(height=5, anchor=BOTTOM) polygon(rounded);
```

## Composition gotchas -- things that look right but break

### diff() inside a BOSL2 distributor -- use for loops instead

BOSL2 distributors (`copies()`, `xcopies()`, `grid_copies()`, `zrot_copies()`) do NOT
reliably support `diff()` as a child. If you need multiple copies of a part that has a
boolean subtraction, use a vanilla `for` loop:

```scad
// WRONG -- diff() silently fails inside copies():
copies([[10,0,0],[-10,0,0]])
    diff() {
        cyl(h=5, d=4, anchor=BOTTOM);
        tag("remove") cyl(h=6, d=2, anchor=BOTTOM);
    }

// CORRECT -- use a for loop instead:
for (x = [10, -10]) {
    translate([x, 0, 0])
        diff() {
            cyl(h=5, d=4, anchor=BOTTOM);
            tag("remove") cyl(h=6, d=2, anchor=BOTTOM);
        }
}
```

### tag("remove") only works inside a diff() scope

`tag("remove")` has no effect unless it is inside a `diff()` call. This is easy to miss when
adding cutouts or features after the main diff() block. Every removal must live inside some
`diff()` -- either the same outer one, or its own wrapper.

### Combining Pattern A and Pattern B in one diff() -- the full enclosure pattern

The most flexible approach mixes both patterns in a single `diff()`:

```scad
WALL = 2; OUTER_W = 80; OUTER_D = 50; OUTER_H = 30;
INNER_W = OUTER_W - WALL*2; INNER_D = OUTER_D - WALL*2; INNER_H = OUTER_H - WALL;
CUTOUT_W = 10; CUTOUT_H = 8; CUTOUT_SPACING = 24;
CUTOUT_Z = WALL + CUTOUT_H / 2;

diff() {
    // Shell -- cavity uses Pattern A (attach inside parent's children block)
    cuboid([OUTER_W, OUTER_D, OUTER_H], anchor=BOTTOM, rounding=1.5, edges=TOP) {
        tag("remove") attach(TOP)
            cuboid([INNER_W, INNER_D, INNER_H + 1], anchor=TOP);
    }
    // Front-face cutouts -- Pattern B siblings inside this same diff()
    // (tag("remove") only works inside a diff() scope -- so keep them here!)
    for (dx = [-CUTOUT_SPACING/2, CUTOUT_SPACING/2])
        translate([dx, -(OUTER_D/2), CUTOUT_Z])
            tag("remove") cuboid([CUTOUT_W, WALL*2, CUTOUT_H]);
}

// PCB standoffs -- additive, placed after main diff, each with their own diff()
// Use for loop, NOT copies(), because diff() doesn't work inside BOSL2 distributors
SO_X = INNER_W/2 - 3; SO_Y = INNER_D/2 - 3;
for (pos = [[SO_X,SO_Y], [-SO_X,SO_Y], [SO_X,-SO_Y], [-SO_X,-SO_Y]])
    translate([pos[0], pos[1], WALL])
        diff() {
            cyl(h=5, d=4, anchor=BOTTOM);
            tag("remove") cyl(h=6, d=2.7, anchor=BOTTOM);
        }
```

## Distributors reference

| Module | Effect |
|--------|--------|
| `xcopies(spacing, n)` | N copies along X |
| `ycopies(spacing, n)` | N copies along Y |
| `zcopies(spacing, n)` | N copies along Z |
| `grid_copies(spacing, n=[nx,ny])` | 2D grid |
| `zrot_copies(n, r)` | N copies around Z at radius r |
| `copies(list_of_points)` | Copies at explicit positions |

## What to read for complex tasks

For reference on specific modules, see:
- `references/bosl2-modules.md` -- full parameter reference for threading, gears, paths, skin
- BOSL2 GitHub wiki: https://github.com/BelfrySCAD/BOSL2/wiki

## When the request is ambiguous

Ask the user for:
1. Key dimensions (overall size, wall thickness, hole sizes)
2. Fastener specs (M3/M4/etc., or imperial)
3. Whether this needs to mate with another part (clearance requirements)
4. Print orientation preference (affects where supports are needed)

Then generate the code. Prefer to make reasonable assumptions and show the code rather than
asking too many questions -- the user can always tweak the parameters at the top of the file.
