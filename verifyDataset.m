%% Verify APTOS Dataset

clear;
clc;

baseFolder = "C:\Users\Vedant\Desktop\archive (2)";

trainFolder = fullfile(baseFolder, "train_images");
valFolder   = fullfile(baseFolder, "val_images");
testFolder  = fullfile(baseFolder, "test_images");

trainCSV = fullfile(baseFolder, "train_1.csv");
valCSV   = fullfile(baseFolder, "valid.csv");
testCSV  = fullfile(baseFolder, "test.csv");


%% Read CSV files

trainTable = readtable(trainCSV);
valTable   = readtable(valCSV);
testTable  = readtable(testCSV);


%% Display dataset sizes

fprintf("===== DATASET SIZES =====\n");

fprintf("Training   : %d images\n", height(trainTable));
fprintf("Validation : %d images\n", height(valTable));
fprintf("Test       : %d images\n", height(testTable));


%% Find actual image files

trainFiles = dir(fullfile(trainFolder, "*.png"));
valFiles   = dir(fullfile(valFolder, "*.png"));
testFiles  = dir(fullfile(testFolder, "*.png"));

fprintf("\n===== ACTUAL IMAGE COUNTS =====\n");

fprintf("Training   : %d images\n", length(trainFiles));
fprintf("Validation : %d images\n", length(valFiles));
fprintf("Test       : %d images\n", length(testFiles));


%% Class distribution

fprintf("\n===== CLASS DISTRIBUTION =====\n");

fprintf("\nTraining:\n");
disp(countcats(categorical(trainTable.diagnosis)));

fprintf("Validation:\n");
disp(countcats(categorical(valTable.diagnosis)));

fprintf("Test:\n");
disp(countcats(categorical(testTable.diagnosis)));


%% Display class names

fprintf("\n===== CLASSES =====\n");

disp(categories(categorical(trainTable.diagnosis)));