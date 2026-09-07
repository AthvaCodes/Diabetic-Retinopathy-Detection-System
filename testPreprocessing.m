%% Test Final Preprocessing

clear;
clc;

addpath("src");

imagePath = "data/sample/e7a372a1c3a4.png";

% Read image
originalImage = imread(imagePath);

% Apply preprocessing
processedImage = preprocessFundusCLAHE(originalImage);

% Display sizes
fprintf("Original image size: ");
disp(size(originalImage));

fprintf("Processed image size: ");
disp(size(processedImage));

% Display images
figure;

subplot(1,2,1);
imshow(originalImage);
title("Original RGB Image");

subplot(1,2,2);
imshow(processedImage);
title("Green Channel + CLAHE + 3 Channel");

sgtitle("Final Preprocessing");