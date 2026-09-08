# pEMv2

This is a collection of MATLAB scripts to employ pEMv2 analysis.  The main codes contain wrapper scripts which run the analysis:
	- main_simulations.m: generates synthetic particle tracks that transition between different diffusive states.
	- main_pEMv2.m: runs pEMv2 on a given set of particle tracks.
	- main_hmmSPT.m: runs pEMv2 on a given set of particle tracks and then runs HMM analysis on the optimal states found by pEMv2.
	- main_visualizations.m: compares the results of pEMv2 with the simulated values.

### pEMv2 (directory)
	
Contains core scripts to execute pEMv2 analysis.  An example of how this can be implemented in practice is shown in main_pEMv2.m.

### HMM (directory)
	
Contains core scripts to execute HMM analysis.  An example of how this can be implemented in practice is shown in main_hmmSPT.m.

### simulations (directory)

Contains core scripts to generate synthetic particle tracks that transition between diffusive states, normal diffuion, confined diffusion, driven diffusion, and fractional Brownian motion.  An example of how this can be implemented in practice is shown in main_simulations.m.

### visualization (directory)

Contains core scripts to generate visualizations of pEMv2 post-analysis, including mean square displacements and velocity autocorrelation functions for each diffusive state. An example of how this can be implemented in practice is shown in main_visualization.m.

### helper (directory)

Contains various helper scripts.

