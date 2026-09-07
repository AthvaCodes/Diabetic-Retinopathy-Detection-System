%% Train Diabetic Retinopathy ResNet-50
clear;
clc;

%% ============================================================
% PROJECT PATH
% ============================================================

projectFolder = fileparts(mfilename("fullpath"));

addpath(fullfile(projectFolder,"src"));

%% ============================================================
% LOAD DATA
% ============================================================

fprintf("Loading training data...\n");

load(fullfile(projectFolder,"trainingData.mat"), ...
    "trainDS", ...
    "valDS", ...
    "testDS", ...
    "classWeights", ...
    "miniBatchSize");

%% ============================================================
% LOAD RESNET-50
% ============================================================

fprintf("\nLoading ResNet-50...\n");

net = imagePretrainedNetwork( ...
    "resnet50", ...
    NumClasses=5);

fprintf("ResNet-50 loaded successfully.\n");

%% ============================================================
% WEIGHTED CROSS-ENTROPY
% ============================================================

fprintf("\nCreating weighted loss...\n");

classWeights = single(classWeights(:));

lossFcn = dlaccelerate(@(Y,T) ...
    crossentropy(Y,T, ...
    Weights=classWeights, ...
    WeightsFormat="C"));

%% ============================================================
% TRAINING OPTIONS
% ============================================================

validationFrequency = max(1, floor(numel(trainDS.Files) / miniBatchSize));

options = trainingOptions("adam", ...
    InitialLearnRate=1e-4, ...
    MaxEpochs=10, ...
    MiniBatchSize=miniBatchSize, ...
    ValidationData=valDS, ...
    ValidationFrequency=validationFrequency, ...
    Metrics="accuracy", ...
    ExecutionEnvironment="gpu", ...
    Plots="training-progress", ...
    Verbose=true);

%% ============================================================
% TRAIN
% ============================================================

fprintf("\n============================================\n");
fprintf("STARTING RESNET-50 TRAINING\n");
fprintf("============================================\n");

trainedNet = trainnet( ...
    trainDS, ...
    net, ...
    lossFcn, ...
    options);

%% ============================================================
% SAVE MODEL
% ============================================================

modelPath = fullfile( ...
    projectFolder, ...
    "models", ...
    "DR_ResNet50.mat");

if ~isfolder(fullfile(projectFolder,"models"))
    mkdir(fullfile(projectFolder,"models"));
end

save(modelPath,"trainedNet");

fprintf("\n============================================\n");
fprintf("TRAINING COMPLETE\n");
fprintf("============================================\n");

fprintf("Model saved to:\n%s\n",modelPath);