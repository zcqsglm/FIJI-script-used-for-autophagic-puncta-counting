//////// all the user agreement and options ////////
options = getBoolean("function of particles properties (size, green, red, (LDR))?");
threshold = getBoolean("Yes = Manual threshold, No = auto threshold");
cropped = getBoolean("Have these images been processed before (instine ROI cropped)? \n Yes = cropped, No = new data set");
LDR = getBoolean("lysotracker deep red?");
n = getNumber("Number of images in one set:" , 3);
k = getNumber("Numbers of images to process:", 3);
dir1 = getDirectory("Image");
new_folder = dir1 + File.separator + "individual_ch/";
new_folder_roi = dir1 + File.separator + "roi/";
File.makeDirectory(new_folder);
File.makeDirectory(new_folder_roi);
Table.create("Table");
//////// //////// 

//////// first green channel must be opened //////// 
j = 1;
	do {	
		title = getTitle();
		dir1 = getDirectory("image");
		length = lengthOf(title);
		title_mCher = substring(title, 0, length -7) +"_c1.tif";
		title_EGFP = substring(title, 0, length -7) +"_c2.tif";
		title_LDR = substring(title, 0, length -7) +"_c3.tif";
		open(dir1 + title_mCher); //open mhcerry 
		if (LDR == 1){
			open(dir1 + title_LDR); 
		}
			run("Images to Stack", "name=Stack title=[]"); // stacked based on order, so the first slice is green and the second is red
			skip = getBoolean("Process(Yes)/Skip(No):"); 
				if (skip == 1){
					if (cropped == 0){ 
						setTool(2);
						run("Enhance Contrast", "saturated=0.25");
						waitForUser("current: " + j + "/" + k + " \n select region of intestine. \n Click 'OK' when done.");
						saveAs("Selection",  new_folder_roi + substring(title, 0, length -3) +"roi");
					} else {open(new_folder_roi + substring(title, 0, length -5) +"2.roi");
					}
	 				run("Measure");
					Area = getResultString("Area", 0);
					
					run("Clear Outside", "stack"); 
					run("Stack to Images");
					selectWindow("Stack-0002");
					run("Duplicate...", " "); // create duplication as "Stack-0002-1 for mcherry"
						if (LDR == 1){
							selectWindow("Stack-0003");
							run("Duplicate...", " "); // create duplication as "Stack-0003-1 for LDR" 
							}
					selectWindow("Stack-0002");
					run("8-bit");
					run("Gaussian Blur...", "sigma=1"); // reduce noise
					run("Subtract Background...", "rolling=20"); //reduce background
						if (threshold == 1) { // manual threshold
							run("Threshold...");
							setAutoThreshold("Triangle dark");  //best default setting, but still need to adjust
							waittitle = "WaitForUserDemo";
							msg = "If necessary, use the \"Threshold\" tool to\nadjust the threshold, then click \"OK\".";
							waitForUser(waittitle, msg);
						} else {
							run("Auto Local Threshold", "method=MidGrey radius=75 parameter_1=0 parameter_2=0 white"); // not sure is auto cna gives us good results
						}
					selectImage("Stack-0002");
					run("Analyze Particles...", "size=25-2000 pixel summarize add"); //find mcherry positive particles and return number 
					roiManager("SelectAll");
					roiManager("Delete");
					selectWindow("Summary");
					IJ.renameResults("Summary","Results"); //mcherry number 
					mCher_count = getResult("Count", 0);
					selectImage("Stack-0001");
					run("Duplicate...", " "); // create duplication as "Stack-0001-1"
					selectWindow("Stack-0001");
					run("8-bit");
					run("Gaussian Blur...", "sigma=1");
					run("Subtract Background...", "rolling=20");
						if (threshold == 1) {
							run("Threshold...");
							setAutoThreshold("Triangle dark");  
							setOption("BlackBackground", false);
							waittitle = "WaitForUserDemo";
							msg = "If necessary, use the \"Threshold\" tool to\nadjust the threshold, then click \"OK\".";
							waitForUser(waittitle, msg);
						} else {
							run("Auto Local Threshold", "method=MidGrey radius=75 parameter_1=0 parameter_2=0 white");
						}
						
					if (LDR == 1 ){
						selectImage("Stack-0003");
						run("8-bit");
						run("Gaussian Blur...", "sigma=1");
						run("Subtract Background...", "rolling=20");
							if (threshold == 1) {
								run("Threshold...");
								setAutoThreshold("Triangle dark");  
								setOption("BlackBackground", false);
								waittitle = "WaitForUserDemo";
								msg = "If necessary, use the \"Threshold\" tool to\nadjust the threshold, then click \"OK\".";
								waitForUser(waittitle, msg);
							} else {
								run("Auto Local Threshold", "method=MidGrey radius=75 parameter_1=0 parameter_2=0 white");
							}
					}
					selectImage("Stack-0001"); //stack-001 is already thresheld, so....
					run("Convert to Mask"); //to binary 
					selectImage("Stack-0002"); // same as above
					run("Convert to Mask");
					if (LDR ==1) {
						selectImage("Stack-0003");
						run("Convert to Mask");
					}
					
					imageCalculator("AND create", "Stack-0001","Stack-0002"); // create double positive gfp and mcherry images, 
					selectImage("Result of Stack-0001");
					run("Threshold..."); 
					setOption("BlackBackground", false);
					setThreshold(100, 255, "raw"); // cause now the image is binary, so what we want now is black, os I set 100 to 255, honestly we can do 254 to 255
					run("Convert to Mask");
					selectImage("Result of Stack-0001");
					run("Analyze Particles...", "size=20-2000 pixel summarize add"); // analyze double positive ones
					selectWindow("Summary");
					IJ.renameResults("Summary","Results");
					mCher_EGFP_count = getResult("Count", 0); // add to log
							if (roiManager("Count") > 0) { // make sure the script is working, when there is 0 double positive one
								roiManager("SelectAll");
								roiManager("Delete");
							}
					
					//////// mcherry and LDR double positive counting //////// 
					if (LDR ==1){ 
						imageCalculator("AND create", "Stack-0002","Stack-0003");
						selectImage("Result of Stack-0002");
						run("Threshold...");
						setOption("BlackBackground", false);
						setThreshold(100, 255, "raw");
						run("Convert to Mask");
						selectImage("Result of Stack-0002");
						run("Analyze Particles...", "size=20-2000 pixel summarize add");
						selectWindow("Summary");
						IJ.renameResults("Summary","Results");
						mCher_LDR_count = getResult("Count", 0);
							if (roiManager("Count") > 0) {
								roiManager("SelectAll");
								roiManager("Delete");
							}
						imageCalculator("AND create", "Result of Stack-0002","Result of Stack-0001");
						selectImage("Result of Result of Stack-0002");
						run("Threshold...");
						setOption("BlackBackground", false);
						setThreshold(100, 255, "raw");
						run("Convert to Mask");
						selectImage("Result of Result of Stack-0002");
						run("Analyze Particles...", "size=20-2000 pixel summarize add");
						selectWindow("Summary");
						IJ.renameResults("Summary","Results");
						mCher_GFP_LDR_count = getResult("Count", 0);
							if (roiManager("Count") > 0) {
								roiManager("SelectAll");
								roiManager("Delete");
							}
					print(title_mCher,Area,mCher_count,mCher_EGFP_count,mCher_LDR_count,mCher_GFP_LDR_count); // print all the results(numbers)
					}
					

					else{
						print(title_mCher,Area,mCher_count,mCher_EGFP_count);
					}
					close("Result of Stack-0001");
					close("Result of Stack-0002");
					close("Result of Result of Stack-0002");	

	
	
	//////// particle analyze //////// 
					if (options == 1 ) {
						imageCalculator("OR create", "Stack-0002","Stack-0001"); // all particles ( green or mccherry )	
						selectImage("Result of Stack-0002");
						if (LDR == 1 ) {
							imageCalculator("OR create", "Result of Stack-0002","Stack-0003"); // all particles ( green or mccherry or lysotracker deep red )
							selectImage("Result of Stack-0002");
						}
						run("Threshold...");
						setOption("BlackBackground", false);
						setThreshold(100, 255, "raw");
						run("Convert to Mask");
						/// create a super mask
						selectImage("Result of Stack-0002");
						run("Analyze Particles...", "size=20-2000 pixel summarize add"); // all particles were analyzed and add to ROI manager
						/// measure every channel ////
						selectWindow("Stack-0002-1"); 
						roiManager("Measure");
						selectWindow("Results");
						saveAs("Measurements", new_folder + substring(title, 0, length -7) +"_Red.csv");
						close("Results");
						selectWindow("Stack-0001-1");
						roiManager("Measure");
						selectWindow("Results");
						saveAs("Measurements", new_folder + substring(title, 0, length -7) +"_Green.csv");
						close("Results");
						if (LDR == 1) {
							selectWindow("Stack-0003-1"); 
							roiManager("Measure");
							selectWindow("Results");
							saveAs("Measurements", new_folder + substring(title, 0, length -7) +"_LDR.csv");
							close("Results");	
						}
					}
							
		Table.set("file_name", j-1 ,title);
		Table.set("area", j-1 ,Area);
		Table.set("mCher_count", j-1 ,mCher_count);
		Table.set("mCher_EGFP_count", j-1 ,mCher_EGFP_count);
		if (LDR ==1){
			Table.set("mCher_LDR_count", j-1 ,mCher_LDR_count);
			Table.set("mCher_GFP_LDR_count", j-1 ,mCher_GFP_LDR_count);
			}	
		close("*");
		}
		open(title_EGFP);
		m = n ;
		while (m > 0){
			run("Open Next");
			m  = m - 1;
		}
	j = j + 1;	
	}
	while (j < k + 1) {
		close("*");
		selectWindow("Table");
		saveAs("Table", dir1 + substring(title, 0, length -7) +"table.txt");
		
	}
	