function motion_detector()
% Main kick off for script... 
% Load the folder into an imageDatastore, start the processing pipeline
    global THRESHOLD 
    global WHITE 
    global BLACK 
    global BOX3
    global BOX5
    global GAUSS 
    global TEMPORAL_SCALE
    global GAUSS_STD

    THRESHOLD = 10;
    WHITE = 255;
    BLACK = 0;
    TEMPORAL_SCALE = 1;
    GAUSS_STD = 4;

    BOX3 = '3x3Box';
    BOX5 = '5x5Box';
    GAUSS = 'gauss';

    % Specify the folder where the files live.
    %myFolder = '/Users/dhanush/Northeastern/2023spring/eece5639/project1/RedChair';
    myFolder = '/Users/dhanush/Northeastern/2023spring/eece5639/project1/Office';
    % Check to make sure that folder actually exists.  Warn user if it doesn't.
    if ~isdir(myFolder)
      errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
      uiwait(warndlg(errorMessage));
      return;
    end

    % Get a list of all files in the folder with the desired file name pattern.
    % filePattern = fullfile(myFolder, '*.jpg'); % Change to whatever pattern you need.
    % theFiles = dir(filePattern);

    video = imageDatastore(myFolder);
    processing_pipeline(video)
end

function processing_pipeline(video)
% Handle the processing of the image datastore after its been loaded

    global TEMPORAL_SCALE
    global GAUSS
    global BOX3
    global BOX5
    % Start at 2nd image, end at length - 1 because the nth term is the 
    % difference of n-1 and n+1
    for k = 2 : length(video.Files) - 1
       previous = readimage(video, k - 1) * TEMPORAL_SCALE;
       next = readimage(video, k + 1) * TEMPORAL_SCALE;
       frame.color = readimage(video, k);

       [frame.gauss_filter, frame.gauss_mask, frame.gauss_movement] = ...
           processing_pipeline_helper(frame.color, previous, next, GAUSS);
       [frame.box3_filter, frame.box3_mask, frame.box3_movement] = ...
           processing_pipeline_helper(frame.color, previous, next, BOX3);
       [frame.box5_filter, frame.box5_mask, frame.box5_movement] = ...
           processing_pipeline_helper(frame.color, previous, next, BOX5);

       display_frame(frame);
    end

    % Gaussian 1D
    % 1/16 * [1 4 6 4 1] over each pixel with respect to time. 
    global WHITE

    for k = 3 : length(video.Files) - 5
        kernelCube = getGaussCube(video, size(readimage(video, 1)));
        temporalCube = getTemporalCube(video, k);
        differentialImage = sum(double(temporalCube) .* kernelCube, 3);

        % Threshold values - above a THRESHOLD and the coresponding pixel should
        % be white, otherwise, black.
        mask = delta_threshold(differentialImage);

        color = readimage(video, k);
        movement = uint8(double(rgb2gray(color)) .* (mask/WHITE));

        % Image
        subplot(2,4,1);
        imshow(color);  
        title('Motion Detected Original Image')
        
        % Filter
        subplot(2,4,2);
        imshow(differentialImage); 
        title('Threshold')
        
        % Filter
        subplot(2,4,3);
        imshow(differentialImage); 
        title('Threshold')
        
        % Filter
        subplot(2,4,4);
        imshow(differentialImage); 
        title('Threshold')
        
        
        subplot(2, 4, [5, 6]);
        scatter3(k, (sqrt(mean2(differentialImage .* differentialImage))),zeros(size(k)), 'r');
        title('Gaussian Mean Noise')
        xlabel('Frame number')
        ylabel('Mean Noise Value')
        zlabel('Z-axis')
        hold on;

        subplot(2, 4, [7, 8]);
        scatter3(k, std2(differentialImage),zeros(size(k)), 'r');
        title('Standard Deviation of Noise')
        xlabel('Frame number')
        ylabel('Standard Deviation')
        zlabel('Z-axis')
        hold on;
        drawnow;
        %subplot(2, 4, [7, 8]);
        %scatter(k, (sqrt(mean2(differentialImage .* differentialImage))), 'r');
        %title('Mean Root Squared Value of Differential')
        %xlabel('Frame number')
        %ylabel('Mean Root Squared')
        %hold on;
        %drawnow;

        %subplot(2, 4, [7, 8]);
        %scatter3(k, (sqrt(mean2(differentialImage .* differentialImage))),zeros(size(k)), 'r');
        %title('Mean Root Squared Value of Differential')
        %xlabel('Frame number')
        %ylabel('Mean Root Squared')
        %zlabel('Z-axis')
        %hold on;
        %drawnow;

    end

end

function gaussCube = getGaussCube(video, imageSize)
    gauss = [1 4 6 4 1] * (1/16);
    differential = [-1 0 1];
    kernel = conv(differential, gauss, 'same');
    differentialImage = ones(imageSize(1), imageSize(2));
    gaussCube = repmat(kernel, [imageSize(1) * imageSize(2), 1]);
    gaussCube = reshape(gaussCube, [imageSize(1), imageSize(2), length(kernel)]);
end

function slice = getTemporalCube(video, k)
    slice = [];
    for i = 1 : 3
        slice = cat(3, slice, rgb2gray(readimage(video, k - 2 + i)));
    end
end

function [filter, mask, movement] = ... 
    processing_pipeline_helper(color, previous, next, filter_selector)
    % Apply spatial filter, threshold values, apply mask
    % filter: the frame with the spatial filter applied
    % mask: the difference between the two frames with the threshold
    % applied
    % movement: the mask applied to the frame
        
    [previous_frame, next_frame] ...
        = apply_spatial_filter(previous, next, filter_selector);

    %imshowpair(previous_frame, next_frame, 'montage')

    filter = rgb2gray(next_frame);
    delta = abs(double(rgb2gray(next_frame)) - double(rgb2gray(previous_frame)));

    % Threshold values - above a THRESHOLD and the coresponding pixel should
    % be white, otherwise, black.
    mask = delta_threshold(delta);

    global WHITE
    movement = uint8(double(rgb2gray(color)) .* (mask/WHITE));
end

function [previous_frame, next_frame] = apply_spatial_filter(previous, next, selector)
% Applies the requested filter to the given frames. returns the frames.
    global BOX3
    global BOX5
    global GAUSS
    global GAUSS_STD

    switch selector
        case BOX3
            [previous_frame, next_frame] = box(3);
        case BOX5
            [previous_frame, next_frame] = box(5);
        case GAUSS
            previous_frame = imgaussfilt(previous, GAUSS_STD);
            next_frame = imgaussfilt(next, GAUSS_STD);
    end

    function [previous_frame, next_frame] = box(n)
        previous_frame = imfilter(previous, (1/(n * n)) * ones(n));
        next_frame = imfilter(next, (1/(n * n)) * ones(n));
    end
end

function mask = delta_threshold(frame)
    global WHITE
    global BLACK
    global THRESHOLD

    frame(abs(frame) >= THRESHOLD) = WHITE;
    frame(abs(frame) < THRESHOLD) = 0;

    mask = frame;
end

function display_frame(frame)
    % Image
    subplot(3,4,1);
    imshow(frame.color);  
    title('Motion Detected Image - Original')
    
   
    % Show gray image of mask 
    subplot(3,4,2);
    imshow(frame.gauss_movement);  % Display mask.
    title('Grayscale Image : Gaussian')
    
    % Show gray image of mask 
    subplot(3,4,3);
    imshow(frame.box3_movement);  % Display mask.
    title('Grayscale Image : 3*3 Box Filter')

    % Show gray image of mask 
    subplot(3,4,4);
    imshow(frame.box5_movement);  % Display mask.
    title('Grayscale Image : 5*5 Box Filter')
    
    
    % Mask
    subplot(3,4,6);
    imshow(frame.gauss_mask); % Multiply by WHITE value to get a binary image 
    title('Masked Image : Gaussian')

     % Mask
    subplot(3,4,7);
    imshow(frame.box3_mask); % Multiply by WHITE value to get a binary image 
    title('Masked Image : 3*3 Box Filter')

    % Mask
    subplot(3,4,8);
    imshow(frame.box5_mask); % Multiply by WHITE value to get a binary image 
    title('Masked Image : 5*5 Box Filter')
    
    % Filter
    subplot(3,4,10);
    imshow(frame.gauss_filter); 
    title('Output - Gaussian Filter After Combining Mask')
    
    
    % Filter
    subplot(3,4,11);
    imshow(frame.box3_filter); 
    title('Output - Box 3 Filter After Combining Mask')
    
    % Filter
    subplot(3,4,12);
    imshow(frame.box5_filter); 
    title('Output- Box 5 Filter After Combining Mask')
    drawnow; % Force display to update immediately.
end