clear;
clc;
close all;

load("D:\Diabetic-Retinopathy-Detection-System-main\models\DR_ResNet50.mat");

[file,path] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png','Fundus Images'}, ...
    'Select Fundus Image');

if isequal(file,0)
    return;
end

img = imread(fullfile(path,file));

figure;
imshow(img);
title("Test Image");

imgInput = imresize(img,[224 224]);

if size(imgInput,3) == 1
    imgInput = cat(3,imgInput,imgInput,imgInput);
end

[label,scores] = classify(net,imgInput);

fprintf("\nPredicted Class: %s\n",string(label));
fprintf("Confidence: %.2f%%\n",max(scores)*100);

figure;
imshow(img);
title("Prediction: " + string(label));