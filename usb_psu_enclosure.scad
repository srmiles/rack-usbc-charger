// Rack-side USB-C charging station — every part fits a 200x200 bed
// 1x Mean Well LRS-200-24 (215x115x30, datasheet Case 207) + N x CKCS U1E (32x20x10, 65W PD)
// PSU metal case is its own enclosure. Printed: end cap (bracket + terminal enclosure + USB holder),
// cap lid, far bracket. Bracket backs sit flat on rack side panel.
// Render: part = "cap" | "lid" | "far" | "sled" (print N) | "test" | "all"
part = "all";

// ---- calibration knobs (measure your parts) ----
N        = 8;     // USB boards
PITCH    = 14;    // board spacing; boards on edge, 10 mm thick -> ~4 mm air (U1E sheet asks 3-5)
PCB_T    = 1.6;   // U1E sheet: 1.6 mm FR-4
PORT_OFF = 2.5;   // PCB mid-plane -> port centre: 0.8 + 3.4/2 (port sits on top face, U1E sheet)
PORT_UP  = 10;    // port centred on 20 mm edge (U1E sheet)
GROOVE   = 1.5;   // PCB edge bite in floor groove (U1E sheet)
PW       = 2.5;   // port wall: thin so plug overmold reaches the 1 mm receptacle overhang
RECEPT   = [3.4+0.3, 9.2+0.3+0.75];  // [Y thick, Z tall]; Z +0.75 after test print (user: 0.5-1 mm short). tight socket for the 1 mm receptacle overhang (U1E sheet aperture + clearance)
PLUG     = [9.5, 14];  // outer recess W x H for plug overmold
// Carrier plate: board screws (4x M2 self-tap) through its edge half-holes onto a plate on its flat side.
// Only the plate edges sit in floor/lid slots -> nothing grips the PCB edges, where the electrolytics sit.
ST       = 1.2;   // plate thickness
SB       = 1.0;   // standoff bosses: clear solder on PCB underside
SR       = 2;     // sled corner radius (clears boss: d4.5 at 4,4)
SH       = 28;   // plate height = 20 PCB + 4 each edge (bosses stay clear of the 1.5 mm slot bite)
HH       = [4, 32-7];    // half-hole centres from PCB front edge: measured 4 from front, 7 from rear
CORD_D   = 7.5;   // AC cord measured 6.5-7 mm, +0.5 clearance; zip-tie anchor takes the pull
RACK_D   = 5.5;   // rack screw clearance (M5)
// -------------------------------------------------

PSU = [215, 115, 30];
PT  = 5;           // plate thickness = air gap behind PSU
EAR = 20;          // ears beyond PSU sides
PR  = 5;           // base plate corner radius
WT  = 6;           // walls thick enough for M3 pilots
CLR = 1;           // PSU width tolerance is ±1 (datasheet)
BL  = 32;          // PCB length; receptacle overhangs 1 mm into port wall
CX  = BL + 18;     // cap depth past PSU end: boards + wiring room to terminals
OV  = 22;          // cap overlap onto PSU top (covers terminal screws)
WH  = PT + PSU.z + 1;
psu_y = [32.5, 82.5];   // datasheet bottom M4 rows
$fn = 32;

X0 = -CX - PW;     // cap outer end (port face)
by = [for (i=[0:N-1]) (PSU.y - (N-1)*PITCH)/2 + i*PITCH];   // port centres along Y
function py(y) = y - PORT_OFF - PCB_T/2 - SB - ST;            // carrier plate -Y face for port at y
LR  = 3;           // lid + cap wall corner radius
lid_xy = [for (x=[X0+8, OV-8], y=[-CLR-WT/2, PSU.y+CLR+WT/2]) [x,y]];

// rounded-rect prism along +X, centred on Y/Z (rounded corners print cleaner)
module rrect(len, wh, r) hull() for (y=[-1,1], z=[-1,1]) translate([0, y*(wh[0]/2-r), z*(wh[1]/2-r)]) rotate([0,90,0]) cylinder(r=r, h=len);
// removes the 4 outer vertical corners of the cap/lid footprint, leaving radius LR
module corner_mask(h) for (i=[0,1], j=[0,1]) {
  x = i ? OV : X0;  y = j ? PSU.y+WT+CLR : -WT-CLR;  sx = i ? -1 : 1;  sy = j ? -1 : 1;
  translate([x,y,0]) difference() {
    translate([sx<0?-LR:-0.01, sy<0?-LR:-0.01, 0]) cube([LR+0.01, LR+0.01, h]);
    translate([sx*LR, sy*LR, -1]) cylinder(r=LR, h=h+2);
  }
}
module m4_csk() { translate([0,0,-1]) cylinder(d=4.5,h=PT+2); translate([0,0,-0.01]) cylinder(d1=8.6,d2=4.5,h=2.3); }
module rack_slot() { translate([0,0,-1]) hull() for (d=[-3,3]) translate([d,0,0]) cylinder(d=RACK_D,h=PT+2); }
module plate(x0, x1, hx) difference() {
  hull() for (x=[x0+PR, x1-PR], y=[-EAR-WT+PR, PSU.y+EAR+WT-PR]) translate([x,y,0]) cylinder(r=PR, h=PT);   // rounded corners
  for (y=psu_y) translate([hx,y,0]) m4_csk();
  for (y=[-WT-EAR/2-2, PSU.y+WT+EAR/2+2]) translate([(x0+x1)/2,y,0]) rack_slot();
}

module cap() {
  difference() {
    union() {
      plate(X0, 32.5+15, 32.5);
      translate([X0+PW+BL+0.3, 0, PT]) cube([2, PSU.y, 4]);                          // PCB backstop
      for (y=[-WT-CLR, PSU.y+CLR]) translate([X0, y, 0]) cube([CX+PW+OV, WT, WH]);   // side walls
      translate([X0, -WT-CLR, 0]) cube([PW, PSU.y+2*(WT+CLR), WH]);                     // port wall
      // cord zip-tie anchor
      translate([-14, -CLR-0.01, PT]) difference() { cube([6,8,10]); translate([-1,2,3]) cube([8,4,2.5]); }
    }
    // USB-C: boards on edge, port faces -X, components on +Y side.
    // Inner 1 mm = tight socket the receptacle shell sits in (takes plug side loads); outer = overmold recess.
    for (y=by) translate([0, y, PT-GROOVE+(SH-20)/2+PORT_UP]) {
      translate([X0+PW-1-0.01, 0, 0]) rrect(1.02, RECEPT, 1.5);   // 1.5 fillet per U1E sheet
      translate([X0-1, 0, 0]) rrect(PW, PLUG, 2.5);
    }
    // carrier-plate grooves in floor, +0.3 print clearance (U1E sheet: 0.25-0.4)
    for (y=by) translate([X0+PW-0.01, py(y)-0.15, PT-GROOVE]) cube([BL+0.3, ST+0.3, GROOVE+1]);
    // AC cord entry in side wall near PSU end, open-top notch
    translate([-5-CORD_D/2, -WT-CLR-1, PT+8]) cube([CORD_D, WT+2, WH]);
    for (p=lid_xy) translate([p.x,p.y,WH-12]) cylinder(d=2.6,h=13);
    // slot-1 screw tips (measured 3.4 mm past plate) pass 0.6 mm from wall -> 1 mm vertical channels, open top for drop-in
    for (x=HH) translate([X0+PW+x-1.75, -CLR-1, PT-GROOVE+(SH-20)/2-2]) cube([3.5, 1.01, WH]);
    // round wall outer corners to match lid (above base plate only)
    translate([0,0,PT]) corner_mask(WH);
  }
}

CD = WH - (PT - GROOVE + SH) + GROOVE;   // comb depth below lid
module lid() difference() {
  union() {
    difference() { translate([X0,-WT-CLR,0]) cube([CX+PW+OV, PSU.y+2*(WT+CLR), 2.5]); translate([0,0,-1]) corner_mask(5); }
    // two slotted combs grip PCB top edges (board top edge at PT-GROOVE+20)
    for (x=[X0+PW+2, X0+PW+BL-5]) translate([x, 0, -CD]) cube([3, PSU.y, CD]);
  }
  for (x=[X0+PW+2, X0+PW+BL-5], y=by) translate([x-1, py(y)-0.15, -CD-1]) cube([5, ST+0.3, GROOVE+1]);
  for (p=lid_xy) translate([p.x,p.y,-1]) cylinder(d=3.4,h=5);
  for (x=[X0+PW+8:7:X0+PW+BL-8]) translate([x, 8, -1]) cube([3, PSU.y-16, 5]);   // vents over boards
}

module far() plate(182.5-15, 182.5+15, 182.5);

// print 8. Plate flat on bed, bosses up; PCB flat face down on bosses, 2G x 6.5 self-tappers through half-holes.
module sled() difference() {
  union() {
    // rounded corners: printed slot corners aren't sharp, square sled corners bind going in
    hull() for (x=[SR, BL-SR], y=[SR, SH-SR]) translate([x,y,0]) cylinder(r=SR, h=ST);
    for (x=HH, y=[(SH-20)/2, SH-(SH-20)/2]) translate([x,y,0]) cylinder(d=4.5, h=ST+SB);
  }
  for (x=HH, y=[(SH-20)/2, SH-(SH-20)/2]) translate([x,y,-1]) cylinder(d=1.8, h=ST+SB+2);   // #2 (2G) self-tap pilot; 6.5 mm screw tip exits 2.7 mm, lands opposite neighbour's screw head (~6 mm clear)
}

module bb(n,x,y) echo(str(n,": ",x," x ",y," mm",(x<=200&&y<=200)?" OK":" TOO BIG"));
bb("cap", CX+PW+32.5+15, PSU.y+2*(EAR+WT));
bb("far", 30, PSU.y+2*(EAR+WT));
echo(str("Power: ", N, "x65W=", N*65, "W worst vs 211W PSU -> ", floor(211*0.95/65), " ports at full 65W"));

if (part=="cap") cap();
if (part=="lid") lid();
if (part=="far") far();
if (part=="sled") sled();
// test print: port-wall corner of the cap (2 board positions: socket, recess, floor slots, backstop) + 1 sled
if (part=="test") {
  intersection() { cap(); translate([X0-1, -WT-CLR-1, -1]) cube([PW+BL+4, by[1]+10+WT+CLR, WH+2]); }
  translate([X0, by[1]+20, 0]) sled();
}
if (part=="all") {
  cap(); far();
  %translate([0,0,PT]) cube(PSU);    // ghost PSU
  translate([0,0,WH]) lid();
}
