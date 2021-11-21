// Molecular Imaging Platform (MIP) (IBMB)
// Elena Rebollo erabmc@ibmb.csic.es
// Fiji lifeline 22 Dec 2015 (from ImageJ 1.50e on)
// This macro creates three channel composites from a list of WF+ICC composites
// A dialog is created to introduce the experiment date and the cell line used so that the folder
//    containing the merge files is identifyed
// The macro extracts two name identifier to look for the matched wf image 
// Created for the Thunder Speck Assay, to deliver composites containing gfpICC (C1), gfpWF (C2) and dapiWF (C)

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
outputDir=Dir+dirDate+"_inflammasomes_"+dirLine+"_mixedComposites";
//print(outputDir);
File.makeDirectory(outputDir);

//
if (!File.exists(outputDir))
      exit("Unable to create directory");
//loop to open ch00 images, call the other channel (ch01), create composite and save
for(i=0;i<lengthOf(FileNames);i++){
	// Open all images in loop
	open(Dir+File.separator+FileNames[i]);
	name=getTitle();
	print(name);
	//select ICC images and, get match names and split GFPICC channel
	if(lengthOf(name)>14) {
		run("Split Channels");
		selectWindow("C2-"+name);
		close();
		selectWindow("C1-"+name);
		rename("icc-gfp");
		run("Red");
		//obtain match names for WF image
		firstIndex=indexOf(name, "_ICC_");  
		print(firstIndex);
		lastIndex=indexOf(name, ".tif"); 
		print(lastIndex);
        baseName1=substring(name, 0, firstIndex);
        print(baseName1);
        baseName2=substring(name, lastIndex-3, lastIndex);
        print(baseName2);
        //open match WF image
        open(Dir+File.separator+baseName1+"_"+baseName2+".tif");
        rename("wf");
        run("Split Channels");
        run("Merge Channels...", "c1=icc-gfp c2=C1-wf c3=C2-wf create");
        saveAs("tiff", outputDir+ "/" +baseName1+"_"+baseName2+"_mixedComposite"); 
        close();   
	}

	else { 
		close();
		}
}

