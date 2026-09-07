function [isValid, quality] = validateFundusQuality(inputImage)

% Convert image to grayscale double
gray = im2double(im2gray(inputImage));

%% 1. Detect retinal field of view

fovMask = gray > 0.05;

% Remove very small regions
fovMask = bwareaopen(fovMask, 500);

% Keep the largest connected region
if any(fovMask(:))
    fovMask = bwareafilt(fovMask, 1);
end

% FOV coverage
fovCoverage = nnz(fovMask) / numel(fovMask);

% We use a conservative threshold.
% APTOS images can naturally have relatively small FOV.
minFOVCoverage = 0.20;

fovOK = fovCoverage >= minFOVCoverage;


%% 2. Check illumination

if any(fovMask(:))
    meanIntensity = mean(gray(fovMask));
else
    meanIntensity = 0;
end

minIntensity = 0.15;
maxIntensity = 0.60;

illuminationOK = ...
    meanIntensity >= minIntensity && ...
    meanIntensity <= maxIntensity;


%% 3. Final Quality Decision

isValid = fovOK && illuminationOK;


%% 4. Store quality information

quality.fovCoverage = fovCoverage;
quality.meanIntensity = meanIntensity;

quality.fovOK = fovOK;
quality.illuminationOK = illuminationOK;

quality.isValid = isValid;

end