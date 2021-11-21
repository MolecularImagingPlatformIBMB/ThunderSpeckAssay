# ThunderSpeckAssay

This set of macros has been created to count the number fo inflammasomes and nuclei (Speck Assay) in cell lines expressing Asc-GFP and stained with Dapi. The pipeline is adapted for multiwell plates imaged in a Thunder 3D Live Cell, using the ICC algprithm on the GFP channel. The macros included are the following:
1. A macro to mount two channel composites from single channel images exported as tif.
2. A macro to create three channel composites containing C1: GFP_ICC; C2: GFP; C3: DAPI (called mixed composites).
3. A macro to calculte a cutoff value in a set of preselected images. This cutoff will differenciate between the folloing cathegories: i) images without cells: ii) images with cell without specks; and iii) images with cells and specks.
4. A macro to fine tune the segmentation fo both specks and nuclei.
5. A macro for the automatic analysis of the whole set of mixed composites; it delivers a data sheet with the results and a list of verification images to track for outliers.
