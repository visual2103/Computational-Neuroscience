# Computational-Neuroscience  
**EEG Preprocessing Pipeline for Visual Perception Analysis**

This repository presents the development of a complete EEG preprocessing pipeline designed for the **Dots_30 visual perception experiment**, which investigates brain activity related to stimulus visibility and perceptual awareness.

The project is conducted by **Alina Macavei**, undergraduate student at the *Faculty of Automation and Computer Science*, specialization in *Computer Science and Information Technology*, *Technical University of Cluj-Napoca (UTCN)*.

The pipeline includes all major preprocessing steps—such as **band-pass filtering, epoch segmentation, ICA-based artifact rejection**, and **baseline correction**—implemented using **MATLAB** and the **FieldTrip** toolbox. Each processing stage is organized into modular scripts for clarity and reproducibility.

The primary focus is on the extraction and analysis of **gamma-band (40 Hz)** activity, which is hypothesized to reflect neural mechanisms involved in **visual awareness**, **attention**, and **perceptual integration**.

## Features
- Compatible with FieldTrip data structures  
- Automatic trial rejection based on variance thresholding  
- ICA configuration and manual component selection  
- Event-related segmentation (ERP/ERSP-ready)  
- Supports experimental structure from Dots_30 protocol  

##🙏 Acknowledgments
Special thanks to TINS Cluj-Napoca and UTCN .
