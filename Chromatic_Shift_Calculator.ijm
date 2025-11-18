// Name: ChromaticShiftCalculator.ijm
// Author: E. Rebollo & J. Boix, Molecular Imaging Platform IBMB
// Fiji version: lifeline 22 December 2015
/* This macro calculates the chromatic shift on confocal 
   images of fluorescent beads. It subtract the beads XY 
   centroid coordinates between the red and green channels
   and delivers the average displacenment*/


//REMOVE PIXEL CALIBRATION
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

//SEPARATE CHANNELS AND RENAME THEM
Channels();

//SEGMENT BEADS
var Name = "red";
SegmentBeads(Name);
var Name = "green";
SegmentBeads(Name);

//CREATE ARRAY CONTAINING RED BEADS CENTOID COORDINATES 
selectWindow("red Laplacian");
run("Set Measurements...", "centroid redirect=None decimal=2");
run("Analyze Particles...", "  circularity=0.0-1.00 exclude clear add");
Count = roiManager("count");
X1=newArray(Count);
Y1=newArray(Count);
for (i=0; i<Count; i++) {
	roiManager("select", i);
	roiManager("measure");	
	X1[i]=getResult("X");
	Y1[i]=getResult("Y");
}

//CREATE ARRAY CONTAINING GREEN BEADS CENTOID COORDINATES 
selectWindow("green Laplacian");
roiManager("reset");
run("Analyze Particles...", "  circularity=0.0-1.00 exclude clear add");
Count = roiManager("count");
X2=newArray(Count);
Y2=newArray(Count);
for (i=0; i<Count; i++) {
	roiManager("select", i);
	roiManager("measure");	
	X2[i]=getResult("X");
	Y2[i]=getResult("Y");
}

//CREATE ARRAYS CONTAINING X AND Y SHIFT 
shiftX=newArray(Count);
shiftY=newArray(Count);
for (i=0; i<Count; i++) {
	shiftX[i]=X2[i]-X1[i];
	shiftY[i]=Y2[i]-Y1[i];
}

//EXTRACT MEAN VALUE FROM SHIFT ARRAYS AND PRINT
Array.getStatistics(shiftX, min, max, mean, std);
print("X shift (px): "+mean);
Array.getStatistics(shiftY, min, max, mean, std);
print("Y shift (px): "+mean);

//CLOSE WINDOWS
close();
close();
selectWindow("Results");
run("Close");
selectWindow("ROI Manager");
run("Close");

function Channels(){
	RawName = getTitle; 
	run("Split Channels");
	selectWindow("C1-"+RawName);
	rename("red");
	selectWindow("C2-"+RawName);
	rename("green");
}

function SegmentBeads(Name){
	selectWindow(Name);
	run("FeatureJ Laplacian", "compute smoothing=3");
	setOption("BlackBackground", false);
	run("Make Binary");
	run("Watershed");
	selectWindow(Name)
	close();
}
