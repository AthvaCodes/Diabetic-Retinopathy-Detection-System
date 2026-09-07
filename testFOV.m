clc;
clear;
close all;

imageFolder = "C:\Users\Vedant\Desktop\archive (2)\train_images";

files = dir(fullfile(imageFolder, "**", "*.png"));

numImages = length(files);

fprintf("Images found: %d\n\n", numImages);

fovCoverage = zeros(numImages, 1);

for i = 1:numImages

    img = imread(fullfile(files(i).folder, files(i).name));

    gray = im2double(im2gray(img));

    % Detect non-black retinal region
    fovMask = gray > 0.05;

    % Remove tiny regions
    fovMask = bwareaopen(fovMask, 500);

    % Keep largest connected region
    if any(fovMask(:))
        fovMask = bwareafilt(fovMask, 1);
    end

    % Calculate percentage of image occupied by retina
    fovCoverage(i) = nnz(fovMask) / numel(fovMask);

end

fprintf("Minimum FOV coverage: %.4f\n", min(fovCoverage));
fprintf("Maximum FOV coverage: %.4f\n", max(fovCoverage));
fprintf("Mean FOV coverage:    %.4f\n", mean(fovCoverage));
fprintf("Median FOV coverage:  %.4f\n", median(fovCoverage));

figure;

histogram(fovCoverage, 30);

xlabel("Retinal FOV Coverage");
ylabel("Number of Images");
title("FOV Coverage Distribution - APTOS");

grid on;

% Sort images by FOV coverage
[sortedFOV, sortedIndex] = sort(fovCoverage);

% Show 10 images with lowest FOV coverage
figure;

for i = 1:10

    idx = sortedIndex(i);

    img = imread(fullfile(files(idx).folder, files(idx).name));

    subplot(2,5,i);
    imshow(img);
    title(sprintf("%.4f", sortedFOV(i)));

end

sgtitle("10 Images With Lowest FOV Coverage");