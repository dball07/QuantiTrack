Spot-On Matlab
--------------------------

# Downloading and Running Spot-On Matlab
This repository contains the Matlab version of Spot-On. The Matlab
version is distributed with the GNU GPL v3 license. Please
download the entire repository as a zipped-file and then open up the
introductory guide "A step-by-step guide to using Spot-On MatLab
version 1.docx" and follow the instructions in there.
Alternatively, if you download the repository and open up the main
script `SpotOn_main.m` and click run, the whole code should run and
produce a series of plots based on the example data.
Please also see the documentation associated with the
[web-version of Spot-On](https://spoton.berkeley.edu/) and the [Spot-On paper](https://elifesciences.org/articles/33125).

##### Update 2017-07-26
Fixed plotting issue on small screen. Enabled weighting: if
`UseWeights=1`, Spot-On will now weigh each histogram at each dT
according to the relative amount of data in the least-squares
fitting.

##### Update 2018-02-02 version 1.04
The variable controlling whether all displacements from all
trajectories will be used has been renamed. `UseAllTraj` is now called
`UseEntireTraj` based on user feedback that the original name was
confusing. We would like to clarify that all trajectories are always
used, but that `UseEntireTraj` controls whether all displacements from a
given trajectory is used (yes if =1, no if =0).
Also improved plotting and performance. Compiling histograms is now
about 30-40% faster.

##### Update 2018-04-24 version 1.05
Minor updates to the plotting. Now, the axes of the plots showing the
residuals and the CDFs are linked, such that zooming on any one plot
applies the corresponding zoom to the other plots. 

# How to cite

Please cite the [Spot-On paper](https://elifesciences.org/articles/33125) in your publications:

    Robust model-based analysis of single-particle tracking experiments with Spot-On

    Anders S Hansen*, Maxime Woringer*, Jonathan B Grimm, Luke D Lavis, Robert Tjian, Xavier Darzacq
    eLife, 2018, 7, e33125. doi: 10.7554/eLife.33125
	
    *These authors contributed equally and are alphabetically listed.




