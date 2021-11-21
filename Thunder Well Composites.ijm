// Molecular Imaging Platform (MIP) (IBMB)
// Elena Rebollo erabmc@ibmb.csic.es;
// Fiji lifeline 22 Dec 2015 (from ImageJ 1.50e on)
// This macro creates two channel composites from a list of single channel tifs created in the Thunder 3D live cell; 
//    channels must contain the substring "RAW_ch00" and "RAW_ch01";
// A dialog is created to introduce the experiment date and the cell line used so that the folder
//    containing the merge files is identifyed
// The macro extracts the baseName (well+column*imageRnumber) and eliminates the TileScan term 
//    at the beginning of the name 
// Created to mount the single channel tifs saved by the LasX software from a multiwell 
//    experiment by exporting images as RAW tif (the option create folders must be deactivated
//    so that all images catch the name and are saved to a unique folder)



//Choose input folder and store path
Dir = getDirectory("Folder to process");
//Create array with file names
FileNames = getFileList(Dir);

//Create dialog to name the composites folder
Dialog.create("My well coordinates");
Dialog.addMessage("Enter experiment name");
Dialog.addString("Enter experiment date", "20200122");
Dialog.addString("Enter cell line", "HT29");
Dialog.show();
dirDate=Dialog.getString();
dirLine=Dialog.getString();

//Create output folder to store the composite images, within the input folder
outputDir=Dir+dirDate+"_inflammasomes_"+dirLine+"_composites";
print(outputDir);
File.makeDirectory(outputDir);
if (!File.exists(outputDir))
      exit("Unable to create directory");
//loop to open ch00 images, call the other channel (ch01), create composite and save
for(i=0;i<lengthOf(FileNames);i++){
	// Condition to open ch00 channels only
	if(matches(FileNames[i],".*RAW_ch00.*")) {
		setBatchMode(true);
		//open image ch00
		open(Dir+File.separator+FileNames[i]);
		//select base name substring
		name=getTitle();
		endIndex=indexOf(name, "_RAW_ch00.tif"); 
        baseName=substring(name, 11, endIndex);
        //open corresponding ch01 image
		c01= replace(FileNames[i], "RAW_ch00.tif", "RAW_ch01.tif");
		open(Dir+File.separator+c01);
		print(name);
		print(c01);
		//rename images for the merge to work (it does not like the "TileScan word)
		selectWindow(name);
		rename("blue");
		selectWindow(c01);
		rename("green");
		//merge channels
		run("Merge Channels...", "c2=green c3=blue create");
		rename(baseName);
		print(baseName);	
		saveAs("tiff", outputDir+ "/" +baseName); 
   		close();	
   		setBatchMode(false);
	}
}