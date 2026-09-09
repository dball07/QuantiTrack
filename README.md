<h1>Getting Started</h1>

<h2>System Requirements</h2>
QuantiTrack has been optimized to run in MATLAB R2023a, and has also been tested with R2024a, R2024b, and R2025a. Some functions may not work in early versions. The following MATLAB toolboxes are required:
-	Image Processing Toolbox
-	Optimization Toolbox
-	Statistics Toolbox
The following MATLAB toolboxes are optional:
-	Parallel Computing Toolbox

<h2>Installation</h2>
<h3>Running QuantiTrack on a local machine</h3>
1. Unpack the zipped folder “QuantiTrack” into your matlab files folder (example (C:\Users\username\Documents\MATLAB\))  <br>
2. Open Matlab  <br>
3. Change the current directory to the QuantiTrack folder  <br>
4. Type QuantiTrack_installer at the MATLAB command prompt, and press enter. This will add the QuantiTrack folder and all sub-folders to the MATLAB search path. A progress bar will appear to let you know how much time is left. During installation, you will be prompted to enter a directory where all tracking results will be saved. It is recommended to create a new folder on a local drive and specify this as the Database location. This folder will subsequently be referred to as the “Track Database.” <br>  

A local copy of default parameter values will also be created the first time QuantiTrack is run. This is to ensure that changed default values are not overwritten when updating the software.

<h3>Running QuantiTrack with MATLAB Online</h3>
QuantiTrack can be run entirely from a web browser through MATLAB Online (matlab.mathworks.com), with no local MATLAB installation required. This document walks a first-time user through loading the software, running the main tracking GUI on a test movie, and retrieving the results. The main analysis-through-tracking workflow is covered here; further analyses (SpotOn, pEMv2, Richardson-Lucy) run identically once a trackTable has been produced.
<h4>Prerequisites</h4>
•	A MathWorks account (free at mathworks.com). Sign-in with a valid institutional license removes the Basic-tier session-time cap; without one, MATLAB Online is capped at 20 h/month. <br>
•	The following MathWorks toolboxes must be included in your MATLAB Online tier: Image Processing, Statistics and Machine Learning, Parallel Computing, Optimization, and Curve Fitting. Most campus licenses include all of these; the free Basic tier includes only the first two, so a free-tier user should upgrade to Basic+ or use a campus license before proceeding. <br>
•	A test movie (multi-page TIFF) uploaded to your MATLAB Drive. Any single-molecule fluorescence movie in .tif format works. <br> 
<h4>Steps</h4>
1.	Sign in to MATLAB Online at https://matlab.mathworks.com with your MathWorks account. A new session launches the MATLAB Desktop in your browser — the layout matches that of the local desktop version (Command Window in the centre, Current Folder on the left, Workspace on the right). <br>
2.	Download the latest QuantiTrack release to your local machine. In the browser session's left-hand Current Folder pane, drag-and-drop the .zip onto MATLAB Drive to upload it. Right-click the uploaded file and choose “Extract”; MATLAB Drive unpacks it in place. <br>
3.	Alternatively, in the Command Window run: <br> 
!git clone https://github.com/dball07/QuantiTrack <br>
which clones the repository directly into MATLAB Drive under ~/MATLAB Drive/QuantiTrack. Both methods produce the same layout. <br>
4.	Change into the QuantiTrack folder by double-clicking the QuantiTrack directory in the left pane and run the installer by typing the following in the Command Window: <br>
QuantiTrack_installer <br>
The installer adds every QuantiTrack subfolder to the MATLAB path with savepath, then prompts you to select a folder in which tracking output files (trackTables, per-movie .mat outputs, figures) will be saved. Choose or create a folder inside MATLAB Drive so the outputs persist between sessions.<br>
5.	Upload the test movie to MATLAB Drive: in the Current Folder pane, click the Upload button (or drag-and-drop the .tif file). Larger files can be uploaded via the MATLAB Drive Connector on a local machine, or streamed from cloud storage such as Google Drive or OneDrive via the corresponding MATLAB Drive integration.<br>
6.	Launch the main tracking GUI. In the Command Window: <br>
QuantiTrack <br>
The QuantiTrack App Designer window opens inside the browser. All interactive controls (file dialogs, threshold sliders, ROI drawing) behave as they do on a local desktop. <br>
7.	In the GUI, load your test movie, set the detection and linking parameters as described in the QuantiTrack User Guide, and run the tracking. Outputs (trackTable_*.mat, summary figures) are written to the folder you selected in step 4.<br>
8.	Retrieve the results. Right-click any output file in the Current Folder pane and choose “Download” to pull it to your local machine; whole folders can be downloaded as a .zip via the same menu. Results also remain in MATLAB Drive between sessions, so a later session can pick up where the previous one left off simply by re-launching QuantiTrack from the same folder.<br>

<h4>Known limits</h4>
The Basic (free) MATLAB Online tier is capped at 20 hours of session time per calendar month and 5 GB of MATLAB Drive storage; a campus license removes the time cap and raises storage to 20 GB. Users processing many long movies should either sign in through a campus license or offload raw data to an external drive and stream in one movie at a time.
Parallel operations (parfor loops inside QuantiTrack) work on MATLAB Online but are limited to the number of workers granted by your tier: typically 4 on a campus license, versus the 8–16 workers available on a modern local workstation. Wall-time for parallel steps scales accordingly. 

