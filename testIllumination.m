clc;
clear;
close all;

imageFolder = "C:\Users\Vedant\Desktop\archive (2)\train_images";

% Find all images inside class folders
files = dir(fullfile(imageFolder, "**", "*.png"));

numImages = length(files);

fprintf("Images found: %d\n\n", numImages);

meanIntensity = zeros(numImages, 1);

for i = 1:numImages

    % Read image
    img = imread(fullfile(files(i).folder, files(i).name));

    % Convert to grayscale double
    gray = im2double(im2gray(img));

    % Find retinal field of view
    fovMask = gray > 0.05;

    % Remove small regions
    fovMask = bwareaopen(fovMask, 500);

    % Keep largest region
    if any(fovMask(:))
        fovMask = bwareafilt(fovMask, 1);
    end

    % Calculate mean intensity only inside retina
    meanIntensity(i) = mean(gray(fovMask));

end

% Statistics
fprintf("Minimum mean intensity: %.4f\n", min(meanIntensity));
fprintf("Maximum mean intensity: %.4f\n", max(meanIntensity));
fprintf("Mean intensity:         %.4f\n", mean(meanIntensity));
fprintf("Median intensity:       %.4f\n", median(meanIntensity));

% Distribution
figure;
histogram(meanIntensity, 30);

xlabel("Mean Retinal Intensity");
ylabel("Number of Images");
title("Illumination Distribution - APTOS");

grid on;

% Sort images by illumination
[sortedIntensity, sortedIndex] = sort(meanIntensity);

% ------------------------------------------------
% 10 darkest images
% ------------------------------------------------
figure;

for i = 1:10

    idx = sortedIndex(i);

    img = imread(fullfile(files(idx).folder, files(idx).name));

    subplot(2,5,i);
    imshow(img);
    title(sprintf("%.4f", sortedIntensity(i)));

end

sgtitle("10 Darkest Fundus Images");


% ------------------------------------------------
% 10 brightest images
% ------------------------------------------------
figure;

for i = 1:10

    idx = sortedIndex(end-i+1);

    img = imread(fullfile(files(idx).folder, files(idx).name));

    subplot(2,5,i);
    imshow(img);
    title(sprintf("%.4f", sortedIntensity(end-i+1)));

end

sgtitle("10 Brightest Fundus Images");