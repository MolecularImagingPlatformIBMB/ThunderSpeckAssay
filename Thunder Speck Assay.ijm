// Elena Rebollo /Molecular IMAGING PLATFORM IBMB
// Fiji lifeline 22 Dec 2015
// This macro uses Highpass plugin and Morphology plugin

// For three channel images containing C1: gfp icc, C2: gfp and C3: dapi
// 1. Counts inflammasomes in gfp icc image 2. Counts nuclei in dapi channel 
// Runs automatically a set of composite images from a folder and creates verification images and a results table
// Two cutoffs needed: 
//      1) for images withpout cells (adds _nocells in the name, and annotates 0 nuclei and 0 inflammasomes in the results table
//      2) for images without inflammasomes (counts nuclei and writes 0 inflammasomes to the results table); 
// Identifies cells with artifacts (dapi channels), adds NaN to the data sheet (code in lines 113-130)
// Cutoff values, segmentation parameters and background value for "no inflammosome signal" should be calculated for each data set 
// using the two provided extra macros (speckAssay_cutoff.ijm and speckAssay_segmentation.ijm).


//CALL ORIGEN AND DESTINATION FOLDERS
imagesFolder=getDirectory("Choose directory containing images");
resultsFolder=getDirectory("Choose directory to save results");
list=getFileList(imagesFolder);
File.makeDirectory(resultsFolder);

//ARRAYS
names=newArray(list.length);
nuclei=newArray(list.length);
inflam=newArray(list.length);

//DIALOGS
Dialog.create("SEGMENTATION PARAMETERS");
Dialog.addMessage("Enter values");
Dialog.addString("FTT Bandpass filter Radius: ", 30);
Dialog.addNumber("CLAHE BLockSize radius: ", 15);
Dialog.addNumber("Laplacian LoG radius: ", 15);
Dialog.addNumber("Cutoff no cells: ", 0.2);
Dialog.addNumber("Cutoff No Inflammasomes: ", 5);
Dialog.addNumber("Inflammasomes background: ", 1000);
Dialog.show();
BPR=Dialog.getString();
BS=Dialog.getNumber();
LoGR=Dialog.getNumber();
cutoffCells=Dialog.getNumber();
cutoffInfla=Dialog.getNumber();
IBG=Dialog.getNumber();

for(i=0; i<list.length; i++){
	showProgress(i+1, list.length);
	
	//OPEN & PREPARE IMAGES 
	open(imagesFolder+list[i]);
	run("Properties...", "channels=3 slices=1 frames=1 unit=px pixel_width=1 pixel_height=1 voxel_depth=1");
	name=File.nameWithoutExtension;
	rename(name);
	print(name);
	names[i]=name;
	prepareImages(name);
		
	//COUNT INFLAMMASOMES
	selectWindow("gfp icc");
	run("Select All");
	setBatchMode(true);
	run("Duplicate...", "title=cutoff");
	run("Median...", "radius=3");
	run("High pass", "radius=5");
	getStatistics(area, mean, min, max, std, histogram);
	cutoff=max*std/1000;
	print("cutoff: "+cutoff);
	selectWindow("cutoff");
	close();
	setBatchMode(false);

	if (cutoff<cutoffCells) {
		//IMAGES WITHOUT CELLS, FILL ARRAYS 0,0
		selectWindow("gfp icc");
		close();
		selectWindow("dapi");
		close();
		selectWindow(name+"_verificationImage");
		saveAs("TIFF", resultsFolder+name+"_noCells.tif");
		close();
		NoInflammasomes=0;
		print("No. of Inflammasomes: "+NoInflammasomes);
		NoNuclei=0;
		print("No. of Nuclei: "+NoNuclei);
		nuclei[i]=NoNuclei;
		inflam[i]=NoInflammasomes;
			
	} else {
		//ANALYSE IMAGE WITH CELLS
		selectWindow("gfp icc");
		//CHECK FOR THE PRESENCE OF INFLAMMASOMES (CUTOFF>=20)
		if (cutoff>=cutoffInfla) {
			selectWindow("gfp icc");
			detectInflammasomesF("gfp icc", IBG);
			roiManager("reset");
			run("Analyze Particles...", "add");
			selectWindow("inflammasomesMask");
			close();
			//Paint rois in verification image
			selectWindow(name+"_verificationImage");
			setForegroundColor(255, 0, 255);
			roiManager("Set Line Width", 6);
			roiManager("deselect");
			roiManager("draw");
			//Count inflammasomes
			NoInflammasomes=roiManager("Count");
			print("No. of Inflammasomes: "+NoInflammasomes);
			roiManager("reset");
			}
			else {
			NoInflammasomes=0;
			print("No. of Inflammasomes: "+NoInflammasomes);
			}

			inflam[i]=NoInflammasomes;
			selectWindow("gfp icc");
			close();
		
			//COUNT NUCLEI
			selectWindow("dapi");
			//ChecK for artifacts
			setBatchMode(true);
			run("Duplicate...", "title=dapiCheck");
			run("Gaussian Blur...", "sigma=10");
			run("Subtract...", "value=10000");
			setAutoThreshold("Otsu dark");
			setOption("BlackBackground", false);
			run("Convert to Mask");
			run("Make Binary");
			run("Analyze Particles...", "size=0-Infinity add");
			NoRegions=roiManager("Count");
			print("Artifacts: "+NoRegions);
			selectWindow("dapiCheck");
			close();
			setBatchMode(false);
			roiManager("reset");

			//Discard images with dapi artifact or havingGITHUB very few cell clumps <5	, they will be "_nocells"
			if (NoRegions>0) {
				selectWindow("dapi");
				close();
				selectWindow(name+"_verificationImage");
				saveAs("TIFF", resultsFolder+name+"_artifact.tif");
				close();
				NoNuclei=NaN;
			
				} else {
					selectWindow("dapi");
					detectNuclei("dapi", BPR, BS, LoGR);
					//Add maxima to the roi manager
					selectWindow("dapiMask");
					run("Analyze Particles...", "add");
					selectWindow("dapiMask");
					close();
					//Count nuclei (selections in the roi manager)
					NoNuclei=roiManager("Count");
					print("No. of Nuclei: "+NoNuclei);
					//print("No. of nuclei: "+NoNuclei);
			
					// PAINT SELECTED NUCLEI ONTO THE VERIFICATION IMAGE
					//Get xy coordinates into arrays
					selectWindow(name+"_verificationImage");
					roiManager("Show All without labels");
					setForegroundColor(255, 255, 0);
					roiManager("Set Line Width", 1);
					roiManager("deselect");
					roiManager("Fill");
					roiManager("Draw");
					saveAs("TIFF", resultsFolder+name+"_processed.tif");
					close();
					//Close windows
					roiManager("reset");
					selectWindow("dapi");
					close();
					
			}
			//FILL nuclei number RESULTS TO ARRAY	
			nuclei[i]=NoNuclei;	
	}
}
	
//CREATE RESULTS TABLE
run("Table...", "name=[Results] width=400 height=300 menu");
print("[Results]", "\\Headings:"+"Image \t No_Nuclei \t No_Inflammasomes");
for(i=0; i<list.length; i++){
	print("[Results]", ""+names[i] + "\t" + nuclei[i] + "\t" + inflam[i]);
}

//SAVE RESULTS TABLE AS .XLS IN RESULTS FOLDER
selectWindow("Results");
saveAs("Text", resultsFolder+"Results.xls");
run("Close");


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function prepareImages(image){
		selectWindow(image);
		run("Split Channels");
		selectWindow("C1-"+image);
		rename("gfp icc");
		selectWindow("C2-"+image);
		rename("gfp");
		run("Mean...", "radius=2");
		selectWindow("C3-"+image);
		rename("dapi");
		run("Duplicate...", "title=blue");
		run("Enhance Contrast...", "saturated=0.5");
		run("Apply LUT");
		run("Mean...", "radius=2");
		run("Merge Channels...", "c2=gfp c3=blue");
		selectWindow("RGB");
		rename(image+"_verificationImage");
	}

function detectInflammasomesF(title, value) {
	selectWindow(title);
	run("Select All");
	run("Subtract...", "value="+value);
	run("Duplicate...", "title=inflammasomesMask");
	//run("Subtract Background...", "rolling=8");
	//run("Median...", "sigma=3");
	run("Variance...", "radius=1");
	run("Gaussian Blur...", "sigma=2");
	setAutoThreshold("Otsu dark");
	run("Convert to Mask");
	//run("Options...", "iterations=2 count=1 do=Dilate");
	//run("Close-");
	//run("Options...", "iterations=1 count=1 do=Dilate");
	//run("Watershed");
	run("Options...", "iterations=1 count=1 do=Erode");
	//run("Watershed");
	//run("Fill Holes");
}
	
function detectNuclei(title, BPR, BS, LoGR) {
	selectWindow(title);
	run("Duplicate...", "title=dapiMask");
	run("Bandpass Filter...", "filter_large="+BPR+" filter_small=15 suppress=None tolerance=5 autoscale saturate");
	run("Enhance Local Contrast (CLAHE)", "blocksize="+BS+" histogram=20 maximum=3 mask=*None*");
	run("FeatureJ Laplacian", "compute smoothing="+LoGR);
	selectWindow("dapiMask");
	close();
	selectWindow("dapiMask Laplacian");
	rename("dapiMask");
	run("8-bit");
	// Find maxima
	run("Find Maxima...", "noise=0 output=[Single Points] exclude light");
	rename("maxima");
	run("Options...", "iterations=2 count=1 do=Dilate");
	selectWindow("dapiMask");
	close();
	//OBTAIN DAPI surface mask
	selectWindow(title);
	run("Duplicate...", "title=dapiMask");
	run("Subtract Background...", "rolling=300");
	run("Enhance Local Contrast (CLAHE)", "blocksize=20 histogram=20 maximum=3 mask=*None* fast_(less_accurate)");
	run("Gaussian Blur...", "sigma=2");
	setAutoThreshold("Default dark");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	run("Make Binary");
	run("Fill Holes");
	run("Options...", "iterations=2 count=1 do=Dilate");
	//cross masks to eliminate maxima that do not overlap with nuclei
	run("GreyscaleReconstruct ", "mask=maxima seed=dapiMask");
	run("Invert");
	selectWindow("maxima");
	close();
}
				
