
keyboardW = 224;
keyboardH = 90;
controllerW = 126;
controllerH = 40;
extraH = 4;

gapW = (keyboardW-controllerW)/2;

difference() {
    translate([-keyboardW/2,0, controllerH + extraH])
    rotate([-asin((controllerH+extraH)/keyboardH),0,0]) 
    difference() {
        union() {
            rotate([asin((controllerH+extraH)/keyboardH),0,0]) 
            translate([gapW,-2.5,-9])
            cube([controllerW , 7, 14]);
        }
        #cube([keyboardW, keyboardH, 2], center=false);
    }

    translate([-controllerW/2,0,0])
    #cube([controllerW, 2, controllerH], center=false);
}