%% Setup Training Pipeline for DR Classification
clear;
clc;

%% ============================================================
% PATHS
% ============================================================

projectFolder = fileparts(mfilename("fullpath"));

% CHANGE ONLY THIS PATH
baseFolder = "D:\archive";

addpath(fullfile(projectFolder, "src"));

%% ============================================================
% DATASET PATHS
% ============================================================

trainFolder = fullfile(baseFolder, "train_images");
valFolder   = fullfile(baseFolder, "val_images");
testFolder  = fullfile(baseFolder, "test_images");

trainCSV = fullfile(baseFolder, "train_1.csv");
valCSV   = fullfile(baseFolder, "valid.csv");
testCSV  = fullfile(baseFolder, "test.csv");

%% ============================================================
% CHECK PATHS
% ============================================================

fprintf("Checking paths...\n");

assert(isfolder(baseFolder), "Dataset folder not found.");
assert(isfolder(trainFolder), "Training image folder not found.");
assert(isfolder(valFolder), "Validation image folder not found.");
assert(isfolder(testFolder), "Test image folder not found.");

assert(isfile(trainCSV), "Training CSV not found.");
assert(isfile(valCSV), "Validation CSV not found.");
assert(isfile(testCSV), "Test CSV not found.");

fprintf("All paths verified.\n");

%% ============================================================
% READ CSV
% ============================================================

trainTable = readtable(trainCSV);
valTable   = readtable(valCSV);
testTable  = readtable(testCSV);

%% ============================================================
% IMAGE PATHS
% ============================================================

trainPaths = fullfile(trainFolder, trainTable.id_code + ".png");
valPaths   = fullfile(valFolder, valTable.id_code + ".png");
testPaths  = fullfile(testFolder, testTable.id_code + ".png");

%% ============================================================
% QUALITY GATE
% TRAINING ONLY
% ============================================================

fprintf("\nChecking training images with Quality Gate...\n");

trainValid = false(height(trainTable),1);

for i = 1:height(trainTable)

    img = imread(trainPaths(i));

    [isValid,~] = validateFundusQuality(img);

    trainValid(i) = isValid;

end

fprintf("\n===== QUALITY GATE RESULTS =====\n");
fprintf("Before Quality Gate : %d\n",height(trainTable));
fprintf("Passed              : %d\n",sum(trainValid));
fprintf("Rejected            : %d\n",sum(~trainValid));

%% ============================================================
% FILTER TRAINING DATA
% ============================================================

trainPaths = trainPaths(trainValid);

trainLabels = categorical( ...
    trainTable.diagnosis(trainValid));

valLabels = categorical(valTable.diagnosis);
testLabels = categorical(testTable.diagnosis);

%% ============================================================
% CLASS WEIGHTS
% ============================================================

numClasses = numel(categories(trainLabels));
totalImages = numel(trainLabels);
classCounts = countcats(trainLabels);

classWeights = totalImages ./ ...
    (numClasses .* classCounts);

fprintf("\n===== CLASS WEIGHTS =====\n");

for i = 1:numClasses
    fprintf("Class %d : %.4f\n", ...
        i-1,classWeights(i));
end

%% ============================================================
% IMAGE DATASTORES
% ============================================================

miniBatchSize = 16;

trainDS = imageDatastore( ...
    trainPaths, ...
    "Labels",trainLabels);

valDS = imageDatastore( ...
    valPaths, ...
    "Labels",valLabels);

testDS = imageDatastore( ...
    testPaths, ...
    "Labels",testLabels);

%% ============================================================
% CUSTOM PREPROCESSING
% ============================================================

trainDS.ReadFcn = @preprocessFundusCLAHE;
valDS.ReadFcn   = @preprocessFundusCLAHE;
testDS.ReadFcn  = @preprocessFundusCLAHE;

%% ============================================================
% MINI-BATCH SIZE
% ============================================================

trainDS.ReadSize = miniBatchSize;
valDS.ReadSize   = miniBatchSize;
testDS.ReadSize  = miniBatchSize;

%% ============================================================
% SAVE PIPELINE VARIABLES
% ============================================================

save(fullfile(projectFolder,"trainingData.mat"), ...
    "trainDS", ...
    "valDS", ...
    "testDS", ...
    "classWeights", ...
    "miniBatchSize");

fprintf("\n============================================\n");
fprintf("TRAINING PIPELINE READY\n");
fprintf("============================================\n");

fprintf("Training images   : %d\n",numel(trainLabels));
fprintf("Validation images : %d\n",numel(valLabels));
fprintf("Test images       : %d\n",numel(testLabels));
fprintf("Mini-batch size   : %d\n",miniBatchSize);