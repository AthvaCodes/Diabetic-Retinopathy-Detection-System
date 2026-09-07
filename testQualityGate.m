%% Test Final Quality Gate

clear;
clc;

addpath("src");

imageFolder = "C:\Users\Vedant\Desktop\archive (2)\train_images";

files = dir(fullfile(imageFolder, "**", "*.png"));

numImages = length(files);

passCount = 0;
rejectCount = 0;

darkCount = 0;
brightCount = 0;
fovCount = 0;

fprintf("Total images: %d\n\n", numImages);

for i = 1:numImages

    img = imread(fullfile(files(i).folder, files(i).name));

    [isValid, quality] = validateFundusQuality(img);

    if isValid

        passCount = passCount + 1;

    else

        rejectCount = rejectCount + 1;

        if ~quality.fovOK
            fovCount = fovCount + 1;
        end

        if quality.meanIntensity < 0.15
            darkCount = darkCount + 1;
        elseif quality.meanIntensity > 0.60
            brightCount = brightCount + 1;
        end

    end

end


%% Display results

fprintf("========== QUALITY GATE RESULTS ==========\n");

fprintf("Total images     : %d\n", numImages);
fprintf("PASS             : %d (%.2f%%)\n", ...
    passCount, passCount/numImages*100);

fprintf("REJECT           : %d (%.2f%%)\n", ...
    rejectCount, rejectCount/numImages*100);

fprintf("\nRejection reasons:\n");

fprintf("Too dark         : %d\n", darkCount);
fprintf("Too bright       : %d\n", brightCount);
fprintf("Invalid FOV      : %d\n", fovCount);