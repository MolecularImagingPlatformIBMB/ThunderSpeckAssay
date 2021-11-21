// Elena Rebollo /Molecular IMAGING PLATFORM IBMB
// Cutoff calculator for speck assay  
// Fiji lifeline 22 Dec 2015
// This macro calculates the cutoff values for a preselected set of images; the obtained values will serve to
// establish the cutoff values in the main macro Thunder Speck Assay.ijm 
// This version works on the first channel (C1) of three channel images (gfp thunder, gfp, dapi).

name=getTitle();
print(name);
run("Split Channels");
selectWindow("C3-"+name);
close();
selectWindow("C2-"+name);
close();
selectWindow("C1-"+name);
run("Select All");
	run("Duplicate...", "title=cutoff");
	run("Median...", "radius=3");
	run("High pass", "radius=5");
	getStatistics(area, mean, min, max, std, histogram);
	cutoff=max*std/1000;
	print(cutoff);
	selectWindow("cutoff");
	close();
	close();

