%% Boundary Case Inspection

imageFolder = "C:\Users\Vedant\Desktop\archive (2)\train_images";

files = dir(fullfile(imageFolder, "**", "*.png"));
numImages = length(files);

fprintf("Total images: %d\n", numImages);

blurScores = zeros(numImages,1);
meanIntensity = zeros(numImages,1);

%% Calculate quality scores

for i = 1:numImages

    img = imread(fullfile(files(i).folder, files(i).name));

    gray = im2double(im2gray(img));

    % Find retinal region
    fovMask = gray > 0.05;
    fovMask = bwareaopen(fovMask,500);

    if any(fovMask(:))
        fovMask = bwareafilt(fovMask,1);
    end

    % Blur score
    laplacian = imfilter(gray,fspecial("laplacian"));
    values = laplacian(fovMask);

    if ~isempty(values)
        blurScores(i) = var(values);
    end

    % Illumination score
    if any(fovMask(:))
        meanIntensity(i) = mean(gray(fovMask));
    end

end


%% BLUR BOUNDARY CASES

% Candidate blur threshold
blurThreshold = 0.00015;

% Find images closest to the threshold
distance = abs(blurScores - blurThreshold);

[~,index] = sort(distance);

figure;

for i = 1:10

    idx = index(i);

    img = imread(fullfile(files(idx).folder,files(idx).name));

    subplot(2,5,i);
    imshow(img);

    title(sprintf("Blur: %.6f",blurScores(idx)));

end

sgtitle("Images Closest to Blur Threshold");


%% ILLUMINATION LOWER BOUNDARY

illuminationLower = 0.15;

distance = abs(meanIntensity - illuminationLower);

[~,index] = sort(distance);

figure;

for i = 1:10

    idx = index(i);

    img = imread(fullfile(files(idx).folder,files(idx).name));

    subplot(2,5,i);
    imshow(img);

    title(sprintf("Intensity: %.3f",meanIntensity(idx)));

end

sgtitle("Images Closest to Lower Illumination Threshold");


%% ILLUMINATION UPPER BOUNDARY

illuminationUpper = 0.55;

distance = abs(meanIntensity - illuminationUpper);

[~,index] = sort(distance);

figure;

for i = 1:10

    idx = index(i);

    img = imread(fullfile(files(idx).folder,files(idx).name));

    subplot(2,5,i);
    imshow(img);

    title(sprintf("Intensity: %.3f",meanIntensity(idx)));

end

sgtitle("Images Closest to Upper Illumination Threshold");

%% Inspect all images below blur threshold

blurThreshold = 0.00010;

lowBlurIndex = find(blurScores < blurThreshold);

fprintf("\nImages below blur threshold %.5f: %d\n", ...
    blurThreshold, length(lowBlurIndex));

figure;

for i = 1:length(lowBlurIndex)

    idx = lowBlurIndex(i);

    img = imread(fullfile(files(idx).folder, files(idx).name));

    subplot(3,4,i);
    imshow(img);

    title(sprintf("%.6f", blurScores(idx)));

end

sgtitle("All Images With Blur Score Below 0.00010");