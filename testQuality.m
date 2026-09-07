clc;
clear;
close all;

addpath("src");

imagePath = "data/sample/e7a372a1c3a4.png";

img = imread(imagePath);

gray = im2gray(img);

laplacian = imfilter(im2double(gray), fspecial("laplacian"));

blurScore = var(laplacian(:));

fprintf("Blur score: %.6f\n", blurScore);