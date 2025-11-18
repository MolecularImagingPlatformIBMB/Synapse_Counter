// Name: SynapsesCounter.ijm
// Author: E. Rebollo & Jaume Boix-Fabrés, Molecular Imaging Platform IBMB
// Fiji version: lifeline 22 December 2015
/* This macro counts synapses in 2D fluorescence confocal images 
   from fixed brain slices stained against validated presynaptic and 
   postsynaptic markers, and Dapi. It analyses automatically all images contained 
   in a source forder and saves verification images and the results
   text file in a folder of choice. Specific parameters to preprocess
   the images need to be adjusted for each case at variables that feed the 
   corresponding function arguments. 
   Thresholds are automatically calculatd for each image in the data set. 
   Nuclei segmentation may need to be adapted for specific cases*/


//CALL ORIGEN AND DESTINATION FOLDERS
imagesFolder=getDirectory("Choose directory containing images");
resultsFolder=getDirectory("Choose directory to save results");
list=getFileList(imagesFolder);
File.makeDirectory(resultsFolder);

//CREATE DIALOG ASKING FOR PIXEL SHIFT
Dialog.create("Pixel shift");
Dialog.addNumber("X translation (pixels):", 0);
Dialog.addNumber("Y translation (pixels):", 0);
Dialog.show;
shiftX=Dialog.getNumber();
shiftY=Dialog.getNumber();

//ASK FOR ONE- OR TWO-DYE NUCLEAR SEGMENTATION
twoDyes=getBoolean("Is nuclear staining also present at green channel?");

//CREATE DIALOG FOR THRESHOLD MODULATION 
Dialog.create("Indicate Cut-off value for puncta assignment:");
Dialog.addMessage("1=50%  2=60%  3=70%  4=80%");
Dialog.addSlider("Green Cut-off:", 1,5,1);
Dialog.addSlider("Red Cut-off:", 1,5,1);
Dialog.show;
cutoffG=Dialog.getNumber();
cutoffR=Dialog.getNumber();

//CREATE ARRAYS TO STORE RESULTS
names=newArray(list.length);
areas=newArray(list.length);
puncta=newArray(list.length);
synapses=newArray(list.length);

//CREATE LOOP TO ANALYZE ALL IMAGES
for(i=0; i<list.length; i++){
	showProgress(i+1, list.length);
	
	//OPEN IMAGE i FROM IMAGES FOLDER
	open(imagesFolder+list[i]);
	
	//GET IMAGE NAME AND ADD IT TO arrayNAMES
	name = File.nameWithoutExtension;
	
	// SEPARATE CHANNELS AND RENAME
	channels();

	//DETECT NUCLEAR BOUNDARIES
	//Preprocess blue and green channels and convert to mask
	if (twoDyes==true) {
	nucleiMask("blue", 2);
	nucleiMask("green", 5);
	//Generate mask of nuclei
	imageCalculator("OR", "blueNucleiMask","greenNucleiMask");
	run("Analyze Particles...", "size=4-Infinity show=Masks clear include");
	rename("maskOfNuclei");
	run("Options...", "iterations=1 count=1 do=Erode");
	//Close extra windows
	selectWindow("blueNucleiMask");
	run("Close");
	selectWindow("greenNucleiMask");
	run("Close");
	}
	
	if (twoDyes==false) {
	nucleiMask2("blue", 8);
	run("Analyze Particles...", "size=4-Infinity show=Masks clear include");
	rename("maskOfNuclei");
	run("Options...", "iterations=1 count=1 do=Erode");
	selectWindow("blueNucleiMask");
	run("Close");
	}
	
	//RETRIEVE & STORE WORKING AREA VALUE
	area = inverseArea("maskOfNuclei");
	
	//PREPROCESS PRE AND POSTSYNAPTIC SIGNALS
	//Correct chromatic shift
	selectWindow("red");
	run("Translate...", "x="+d2s(shiftX,2)+" y="+d2s(shiftY,2)+" interpolation=Bilinear");
	//preprocess signals
	preprocessSignal("green", 15, 0);
	preprocessSignal("red", 15, 2);

	//DETECT POSTSYNAPTIC PUNCTA (GREEN)
	detectPuncta("green", "maskOfNuclei", 2);

	//CALCULATE THRESHOLD FOR GREEN DISCRIMINATION
	thresholdGreen = thresholdROIs("green", cutoffG );
	
	//DISCARD LOW QUALITY PUNCTA
	noPuncta = discardROIs("green", thresholdGreen);
	
	//CALCULATE THRESHOLD FOR RED DISCRIMINATION
	thresholdRed = thresholdROIs("red", cutoffR);
	
	//DISCARD NON SYNAPTIC PUNCTA
	noSynapses = discardROIs("red", thresholdRed);

	//CREATE VERIFICATION IMAGE 
	verificationImage("red", "green", "blue");
	//Save verification image to results folder
	saveAs("TIFF", resultsFolder+name+"_processed.tif");
	close();
	roiManager("reset");

	//FILL RESULTS TO ARRAYS
	names[i] = name;
	areas[i] = area;
	puncta[i] = noPuncta;
	synapses[i] = noSynapses;

}

//CREATE RESULTS TABLE
run("Table...", "name=[Results] width=400 height=300 menu");
print("[Results]", "\\Headings:"+"Image \t Area \t No Puncta \t No Synapses");
for(i=0; i<list.length; i++){
	print("[Results]", ""+names[i] + "\t" + areas[i] + "\t" + puncta[i] + "\t" + synapses[i]);
}

//SAVE RESULTS TABLE AS .XLS IN RESULTS FOLDER
selectWindow("Results");
saveAs("Text", resultsFolder+"Results.xls");
run("Close");


//LIST OF USER-DEFINED FUNCTIONS
function channels(){
	rawName = getTitle; //Stores the name of the original file
	run("Split Channels");
	selectWindow("C3-"+rawName);
	rename("blue");
	selectWindow("C2-"+rawName);
	rename("green");
	selectWindow("C1-"+rawName);
	rename("red");
}

function nucleiMask(image, gaussianRadius) {
	selectWindow(image);
	run("Duplicate...", "title="+image+"NucleiMask");
	run("Gaussian Blur...", "sigma=gaussianRadius");
	setAutoThreshold("Li dark");
	run("Convert to Mask");
	run("Fill Holes");
}

function nucleiMask2(image, gaussianRadius) {
	selectWindow(image);
	run("Duplicate...", "title="+image+"NucleiMask");
	run("Enhance Local Contrast (CLAHE)", "blocksize=50 histogram=30 maximum=2 mask=*None* fast_(less_accurate)");
	run("Gaussian Blur...", "sigma=gaussianRadius");
	setAutoThreshold("Li dark");
	run("Convert to Mask");
	run("Fill Holes");
}

function inverseArea(image){
		selectWindow(image);
		setAutoThreshold("Default dark");
		run("Set Measurements...", "area redirect=None decimal=2");
		run("Analyze Particles...", "display clear");
		area=getResult("Area", 0);
		return area;
}

function preprocessSignal(image, rollingRadius, medianRadius) {
	selectWindow(image);
	run("Subtract Background...", "rolling=rollingRadius sliding");
	run("Median...", "radius=medianRadius");
}

function detectPuncta(image1,image2,logRadius) {
	selectWindow(image1);
	run("FeatureJ Laplacian", "compute smoothing="+logRadius);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Watershed");
	//Remove nuclear spots
	imageCalculator("Subtract", image1+" Laplacian", image2);
	roiManager("Reset");
	run("Analyze Particles...", "size=0.00-2 circularity=0.4-1.00 exclude clear add");
	//Close masks
	selectWindow(image2);
	run("Close");
	selectWindow(image1+" Laplacian");
	run("Close");
}

function thresholdROIs(image, cutoff) {
	selectWindow(image);
	run("Set Measurements...", "integrated redirect=None decimal=2");
	roiManager("deselect");
	roiManager("measure");
	//Create IntDen array and obtain median
	noRois=roiManager("count");
	intDensities=newArray(noRois);
	for (j=0;j<noRois;j++) {
		intDensities[j]=getResult("IntDen",j);
		}
	Array.sort(intDensities);
	lengthArray=lengthOf(intDensities);

	if (lengthArray%2==0) {lengthArray=lengthArray+1;}
	t=round(lengthArray*(0.6-0.1*cutoff));
	threshold=intDensities[t];
	return threshold;
}

function discardROIs(image, threshold){
	selectWindow(image);
	run("Select All");
	run("Set Measurements...", "integrated redirect=None decimal=2");
	//Dicard ROIs below threshold value
	noRois = roiManager("count");
	for(j=0; j<noRois; j++){
		roiManager("select", j);
		roiManager("measure");
		value=getResult("IntDen",0);
		if(value < threshold) {
			roiManager("delete");
			j--;
			noRois--;
			}
		run("Clear Results");
		}
	return noRois;
}

function verificationImage(image1, image2, image3){
	run("Merge Channels...", "c1="+image1+" c2="+image2+" c3="+image3+" create");
	run("RGB Color");
	//Draw selections into image
	setForegroundColor(255, 255, 255);
	roiManager("deselect");
	roiManager("draw");
	//Close windows & reset ROI Manager
	selectWindow("Composite");
	close();
}