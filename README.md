🔬 Synapse Density Quantification using Fiji (Synapse_Counter)
This repository hosts the Fiji macro scripts and supplementary data for the automated quantification of synapse density in 2D confocal images of fixed immunolabeled neural tissue sections.
The full protocol, including detailed methods and rationale, is described in the published chapter:
•	Citation: Rebollo E*, Boix-Fabres J, Arbones M. Automated macro approach to quantify synapse density in 2D confocal images from fixed immunolabeled neural tissue sections. Methods Mol Biol. 2019; 2040:71-97. * Corresponding author.
•	DOI: 10.1007/978-1-4939-9686-5_5
 
🌟 Overview
The macro provides a straightforward and automated method for exploratory and high-content synapse screenings, especially when a high number of images (hundreds-to-thousands) need to be analyzed to obtain robust statistical information.
The core process uses ImageJ/Fiji's macro language to:
1.	Segment nuclei (DNA staining) to calculate the non-nuclear working area for normalization. 
2.	Correct for chromatic shift between channels. 
3.	Detect postsynaptic puncta using the Laplacian of Gaussian (LoG) algorithm. 
4.	Apply a double discrimination test based on Integrated Density (IntDen) to select only bona fide synaptic sites (puncta that are high quality and overlap with presynaptic signal). 
 
🤝 Contributing
This script is highly adaptable. The protocol rationale can be extended to prospective studies of excitatory glutamateric synapses by adjusting variables and functions as explained in the chapter (e.g., changing parameters for image preprocessing or adapting the nuclear segmentation strategy). 

