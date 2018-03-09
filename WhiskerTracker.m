function [whiskerAngle] = WhiskerTracker(filename,ImgParams)
%   function [whiskerAngle] = WhiskerTracker(filename)
%
%   Author: Aaron Winder
%   Affiliation: Engineering Science and Mechanics, Penn State University
%   https://github.com/awinde
%
%   DESCRIPTION: Reports the mean angle of detected whiskers as a time
%   series. This version relies on a GPU for speed. 
%
%_______________________________________________________________
%   PARAMETERS:
%               filename - [string]
%
%               ImgParams - [struct] contains the fields:
%                               height - [int] height of the grabbed
%                               whisker images in pixels, this value can be
%                               found in the .tdms notes.
%
%                               width - [int] width of the grabbed whisker
%                               images in pixels, this value can be found
%                               in the .tdms notes.
%
%                               BitDepth - [string] code denoting the bit
%                               depth of the images. For the current
%                               whisker camera configuration this should be
%                               '*uint8'
%_______________________________________________________________
%   RETURN:
%               whiskerAngle - [int array] has bit depth equal to the bit
%               depth of the grabbed images
%_______________________________________________________________

% Variable Setup
theta = -40:80; % Angles used for radon transform

% Import whisker movie
import_start = tic;
whiskCam_frames = ReadBinaryFileToMatrix(filename,...
    ImgParams.height, ImgParams.width, ImgParams.bitDepth, 'l');
import_time = toc(import_start);
display([mfilename ': Binary file import time was ' ...
    num2str(import_time) ' seconds.']);

% Calculate the gradient of each image to emphasize whisker edges
imgType = class(whiskCam_frames);
imageGradients = zeros(size(whiskCam_frames),imgType);
for frameNum = 1:size(whiskCam_frames,3)
    indFrame = whiskCam_frames(:,:,frameNum);
    indFrame_gradient = gradient(double(indFrame));
    imageGradients(:,:,frameNum) = cast(indFrame_gradient,imgType);
end

% Transfer the images to the GPU
gpu_trans1 = tic;
gpu_frame = gpuArray(imageGradients);
gpu_transfer = toc(gpu_trans1);
display([mfilename ': GPU transfer time was ' ...
    num2str(gpu_transfer) ' seconds.']);

% PreAllocate array of whisker angles, use NaN as a place holder
whiskerAngle = NaN*ones(1,length(imageGradients));
radon_time1 = tic;
for f = 1:(length(imageGradients)-1);
    % Radon on individual frame
    [R,~] = radon(gpu_frame(:,:,f),theta);
    
    % Get transformed image from GPU and calculate the variance
    col_var = var(gather(R));
    
    % Sort the columns according to variance
    ord_var = sort(col_var);
    
    % Choose the top 0.1*number columns with the highest variance
    thresh = round(numel(ord_var)*0.9);
    sieve = gt(col_var,ord_var(thresh));
    
    % Associate the columns with the corresponding whisker angle
    angles = nonzeros(theta.*sieve);
    
    % Calculate the average of the whisker angles
    whiskerAngle(f) = mean(angles);
end
radon_time = toc(radon_time1);
display([mfilename ': Whisker Tracking time was ' ...
    num2str(radon_time) ' seconds.']);

inds = isnan(whiskerAngle)==1;
whiskerAngle(inds) = [];


