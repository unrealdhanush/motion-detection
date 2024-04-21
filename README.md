# Motion Detection using Simple Image Filtering

## ABOUT THIS SCRIPT
This MATLAB script detects motion between sequential frames of video stored as image files in a specified directory. It employs various filters (Gaussian, 3x3 Box, and 5x5 Box) to analyze the images and highlight motion changes.

## FEATURES
- Adjustable motion detection sensitivity using global threshold settings.
- Utilization of Gaussian, 3x3 Box, and 5x5 Box filters for image processing.
- Visual display of processing results for each filter type.

## REQUIREMENTS
- MATLAB environment.
- Image Processing Toolbox for MATLAB.

## INSTALLATION
No installation needed other than ensuring MATLAB and the Image Processing Toolbox are set up on your system. Place the script `motion_detector.m` in your MATLAB workspace.

## SETUP
1. Modify the `myFolder` variable in the `motion_detector` function to the path where your video files (images) are located.
2. Fine-tune the detection by adjusting the `THRESHOLD`, `TEMPORAL_SCALE`, and `GAUSS_STD` variables.

## USAGE
To execute the script, type the following in your MATLAB command window:
```motion_detector()```

## CONFIGURATION PARAMETERS
- **THRESHOLD**: Sets the sensitivity of motion detection.
- **TEMPORAL_SCALE**: Enhances or reduces the effect of time in motion detection.
- **GAUSS_STD**: Controls the blurriness of the Gaussian filter, impacting motion localization.

## OUTPUT
The script outputs its results in a MATLAB figure window displaying:
- The original image
- Detected motion via each filter type
- Binary masks and filtered outputs for each detection method

Adjust script paths and parameters to fit your specific requirements and directory structure. 
Check out the ```results``` folder for results generated on the ```RedChair``` and ```Office``` data.
