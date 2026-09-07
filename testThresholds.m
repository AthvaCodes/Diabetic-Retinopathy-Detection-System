%% Quality Gate Threshold Analysis

imageFolder = "C:\Users\Vedant\Desktop\archive (2)\train_images";

% Find all PNG images inside class subfolders
files = dir(fullfile(imageFolder, "**", "*.png"));

numImages = length(files);

fprintf("Total images: %d\n", numImages);

% Preallocate
blurScores = zeros(numImages, 1);
meanIntensity = zeros(numImages, 1);

%% Calculate Blur and Illumination

for i = 1:numImages

    img = imread(fullfile(files(i).folder, files(i).name));

    % Convert to grayscale double
    gray = im2double(im2gray(img));

    % Detect retinal region
    fovMask = gray > 0.05;

    % Remove tiny regions
    fovMask = bwareaopen(fovMask, 500);

    % Keep largest region
    if any(fovMask(:))
        fovMask = bwareafilt(fovMask, 1);
    end

    % ---- Blur ----
    laplacian = imfilter(gray, fspecial("laplacian"));
    laplacianValues = laplacian(fovMask);

    if ~isempty(laplacianValues)
        blurScores(i) = var(laplacianValues);
    else
        blurScores(i) = 0;
    end

    % ---- Illumination ----
    if any(fovMask(:))
        meanIntensity(i) = mean(gray(fovMask));
    else
        meanIntensity(i) = 0;
    end

end


%% ILLUMINATION LOWER THRESHOLDS

fprintf("\n===== ILLUMINATION LOWER THRESHOLDS =====\n");

illuminationThresholds = [0.10 0.12 0.15 0.18 0.20 0.25];

for t = illuminationThresholds

    rejected = sum(meanIntensity < t);
    percentage = rejected / numImages * 100;

    fprintf("Lower threshold %.2f -> %d images rejected (%.2f%%)\n", ...
        t, rejected, percentage);

end


%% ILLUMINATION UPPER THRESHOLDS

fprintf("\n===== ILLUMINATION UPPER THRESHOLDS =====\n");

upperThresholds = [0.50 0.55 0.60 0.65 0.70];

for t = upperThresholds

    rejected = sum(meanIntensity > t);
    percentage = rejected / numImages * 100;

    fprintf("Upper threshold %.2f -> %d images rejected (%.2f%%)\n", ...
        t, rejected, percentage);

end


%% BLUR THRESHOLDS

fprintf("\n===== BLUR THRESHOLDS =====\n");

blurThresholds = [0.00005 0.00008 0.00010 0.00015 0.00020 0.00025];

for t = blurThresholds

    rejected = sum(blurScores < t);
    percentage = rejected / numImages * 100;

    fprintf("Blur threshold %.5f -> %d images rejected (%.2f%%)\n", ...
        t, rejected, percentage);

end