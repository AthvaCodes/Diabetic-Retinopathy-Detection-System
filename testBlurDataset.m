clc;
clear;
close all;

% APTOS training image folder
imageFolder = "C:\Users\Vedant\Desktop\archive (2)\train_images";

% Search recursively inside all subfolders
files = dir(fullfile(imageFolder, "**", "*.png"));

% Number of images to test
numImages = length(files);

fprintf("Images found: %d\n", length(files));
fprintf("Images being tested: %d\n\n", numImages);

blurScores = zeros(numImages, 1);

for i = 1:numImages

    % Complete path to image
    imagePath = fullfile(files(i).folder, files(i).name);

    % Read image
    img = imread(imagePath);

    % Convert to grayscale
    gray = im2double(im2gray(img));

% Find retinal field of view
fovMask = gray > 0.05;

% Remove small unwanted regions
fovMask = bwareaopen(fovMask, 500);

% Keep the largest connected region
if any(fovMask(:))
    fovMask = bwareafilt(fovMask, 1);
end

% Laplacian
laplacian = imfilter(gray, fspecial("laplacian"));

% Calculate variance only inside the retinal region
laplacianValues = laplacian(fovMask);

blurScores(i) = var(laplacianValues);

end

% Statistics
fprintf("Minimum blur score: %.6f\n", min(blurScores));
fprintf("Maximum blur score: %.6f\n", max(blurScores));
fprintf("Mean blur score:    %.6f\n", mean(blurScores));
fprintf("Median blur score:  %.6f\n", median(blurScores));

% Histogram
figure;
histogram(blurScores, 20);

xlabel("Laplacian Variance");
ylabel("Number of Images");
title("Blur Score Distribution - APTOS");

grid on;

% Sort images by blur score
[sortedScores, sortedIndex] = sort(blurScores);

% Show the 10 images with lowest blur scores
figure;

for i = 1:10

    idx = sortedIndex(i);

    img = imread(fullfile(files(idx).folder, files(idx).name));

    subplot(2,5,i);
    imshow(img);
    title(sprintf("%.6f", sortedScores(i)));

end

sgtitle("10 Images With Lowest Blur Scores");