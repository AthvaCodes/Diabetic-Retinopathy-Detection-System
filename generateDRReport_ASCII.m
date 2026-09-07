%% DIABETIC RETINOPATHY FINAL TEST AND REPORT GENERATOR
% Uses the previously trained ResNet model.

clearvars -except net
clc
close all

%% 1. SELECT FUNDUS TEST IMAGE

[fileName,filePath] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.bmp','Fundus Images'}, ...
    'Select Fundus Test Image');

if isequal(fileName,0)
    disp('No image selected.');
    return
end

imagePath = fullfile(filePath,fileName);
fprintf('\nSelected test image:\n%s\n',imagePath);

%% 2. LOAD IMAGE

originalImage = imread(imagePath);

if size(originalImage,3) == 1
    originalImage = cat(3,originalImage,originalImage,originalImage);
end

%% 3. PREPARE IMAGE

img = imresize(originalImage,[224 224]);
img = im2single(img);

%% 4. LOAD TRAINED MODEL

if ~exist('net','var')

    fprintf('\nNo model currently loaded.\n');
    fprintf('Select the trained MATLAB model file.\n\n');

    [modelFile,modelPath] = uigetfile( ...
        {'*.mat','MATLAB Model'}, ...
        'Select Trained DR Model');

    if isequal(modelFile,0)
        error('No trained model selected.');
    end

    modelFullPath = fullfile(modelPath,modelFile);
    fprintf('Loading trained model:\n%s\n',modelFullPath);

    loadedData = load(modelFullPath);
    variables = fieldnames(loadedData);
    foundModel = false;

    for i = 1:numel(variables)

        candidate = loadedData.(variables{i});

        if isa(candidate,'dlnetwork') || ...
           isa(candidate,'SeriesNetwork') || ...
           isa(candidate,'DAGNetwork')

            net = candidate;
            foundModel = true;
            fprintf('Model variable found: %s\n',variables{i});
            break
        end
    end

    if ~foundModel
        error('No compatible neural network was found in the MAT file.');
    end

else

    fprintf('\nUsing trained model already loaded as net.\n');

end

%% 5. MODEL INFORMATION

fprintf('\n============================================\n');
fprintf('           TRAINED MODEL LOADED\n');
fprintf('============================================\n');
fprintf('Network type: %s\n',class(net));
fprintf('============================================\n');

%% 6. DR PREDICTION

dlImg = dlarray(img,'SSC');
rawScores = predict(net,dlImg);
rawScores = extractdata(rawScores);
rawScores = double(rawScores(:));

%% 7. CONVERT OUTPUT TO PROBABILITIES

if all(rawScores >= 0) && abs(sum(rawScores) - 1) < 0.01
    probabilities = rawScores;
else
    probabilities = softmax(rawScores);
end

probabilities = double(probabilities(:));

%% 8. DETERMINE PREDICTED CLASS

[confidence,idx] = max(probabilities);
predictedGrade = idx - 1;

classNames = ["No DR","Mild","Moderate","Severe","Proliferative DR"];
gradeLabel = classNames(idx);

%% 9. DISPLAY PREDICTION

fprintf('\n');
fprintf('============================================\n');
fprintf('        DR SEVERITY ANALYSIS\n');
fprintf('============================================\n');
fprintf('Image      : %s\n',fileName);
fprintf('DR Grade   : %d (%s)\n',predictedGrade,gradeLabel);
fprintf('Confidence : %.2f%%\n',confidence * 100);

fprintf('\nClass probabilities:\n');

for c = 1:numel(classNames)
    fprintf('Grade %d (%s): %.2f%%\n', ...
        c - 1,classNames(c),probabilities(c) * 100);
end

fprintf('============================================\n');

%% 10. GENERATE GRAD-CAM

featureLayer = 'res5c_branch2c';

fprintf('\nGenerating Grad-CAM...\n');

try
    scoreMap = gradCAM( ...
        net,img,idx, ...
        'FeatureLayer',featureLayer);
catch ME
    fprintf('\nSpecified Grad-CAM layer failed.\n');
    fprintf('%s\n',ME.message);
    fprintf('Trying automatic Grad-CAM layer selection.\n');
    scoreMap = gradCAM(net,img,idx);
end

%% 11. NORMALIZE GRAD-CAM

scoreMap = imresize(scoreMap,[224 224]);
scoreMap = double(scoreMap);
scoreMap = scoreMap - min(scoreMap(:));

maxCAM = max(scoreMap(:));

if maxCAM > 0
    scoreMap = scoreMap ./ maxCAM;
end

%% 12. PREPARE DISPLAY IMAGE

displayImage = imresize(originalImage,[224 224]);

if size(displayImage,3) == 1
    displayImage = cat(3,displayImage,displayImage,displayImage);
end

displayImage = im2uint8(displayImage);
originalResized = displayImage;

%% 13. GRAYSCALE GRAD-CAM BACKDROP

grayImage = rgb2gray(displayImage);
grayDisplay = repmat(grayImage,[1 1 3]);

%% 14. CREATE RETINAL MASK

retinaMask = grayImage > 10;
retinaMask = imfill(retinaMask,'holes');
retinaMask = bwareafilt(retinaMask,1);

%% 15. RESTRICT GRAD-CAM TO RETINA

camRetina = scoreMap;
camRetina(~retinaMask) = 0;

%% 16. FIND HIGH-ACTIVATION REGIONS

threshold = 0.90;

regionMask = camRetina >= threshold;
regionMask = regionMask & retinaMask;
regionMask = bwareaopen(regionMask,15);
regionMask = imdilate(regionMask,strel('disk',2));

%% 17. FIND REGION BOUNDING BOXES

stats = regionprops(regionMask,'BoundingBox','Area');

%% 18. CREATE RESULT FOLDER

[~,imageName,~] = fileparts(fileName);

resultFolder = fullfile(filePath,'DR_Results');

if ~exist(resultFolder,'dir')
    mkdir(resultFolder);
end

fprintf('\nResult folder:\n%s\n',resultFolder);

%% 19. CREATE FINAL REPORT FIGURE

fig5 = figure( ...
    'Name','Diabetic Retinopathy Final Report', ...
    'Color',[0.06 0.06 0.06], ...
    'Position',[50 50 1700 850]);

%% PANEL 1 - ORIGINAL IMAGE

ax0 = axes( ...
    'Parent',fig5, ...
    'Position',[0.02 0.10 0.29 0.76]);

imshow(originalResized,'Parent',ax0);
axis(ax0,'image');
axis(ax0,'off');

title(ax0,'Original Fundus Image', ...
    'Color','white','FontSize',15,'FontWeight','bold');

%% PANEL 2 - GRAD-CAM

ax1 = axes( ...
    'Parent',fig5, ...
    'Position',[0.33 0.10 0.29 0.76]);

imshow(grayDisplay,'Parent',ax1);
hold(ax1,'on');

camImage = imagesc(ax1,scoreMap);
set(camImage,'AlphaData',0.38);
colormap(ax1,jet);

%% ATTENTION BOXES

numRegions = 0;

if ~isempty(stats)

    areas = [stats.Area];
    [~,order] = sort(areas,'descend');
    maxRegions = min(3,numel(order));

    for k = 1:maxRegions

        s = stats(order(k));

        if s.Area < 50
            continue
        end

        numRegions = numRegions + 1;

        rectangle(ax1, ...
            'Position',s.BoundingBox, ...
            'EdgeColor','black', ...
            'LineWidth',3);

        text(ax1, ...
            s.BoundingBox(1), ...
            max(1,s.BoundingBox(2)-5), ...
            sprintf('%d',numRegions), ...
            'Color','white', ...
            'FontSize',13, ...
            'FontWeight','bold', ...
            'BackgroundColor','black', ...
            'Margin',2);
    end
end

axis(ax1,'image');
axis(ax1,'off');

title(ax1,'Grad-CAM and Attention Regions', ...
    'Color','white','FontSize',15,'FontWeight','bold');

hold(ax1,'off');

cb = colorbar(ax1);
cb.Position = [0.625 0.10 0.014 0.76];
cb.Label.String = 'Grad-CAM Activation';
cb.Label.Color = 'white';
cb.Label.FontSize = 11;
cb.Label.FontWeight = 'bold';
cb.Color = 'white';

%% PANEL 3 - REPORT INFORMATION

ax2 = axes( ...
    'Parent',fig5, ...
    'Position',[0.70 0.10 0.28 0.76]);

axis(ax2,[0 1 0 1]);
axis(ax2,'off');

text(ax2,0.02,0.96,'DIABETIC RETINOPATHY', ...
    'Color','white','FontSize',22,'FontWeight','bold', ...
    'VerticalAlignment','top');

text(ax2,0.02,0.89,'AI-Based Fundus Image Assessment', ...
    'Color',[0.75 0.75 0.75],'FontSize',12, ...
    'VerticalAlignment','top');

line(ax2,[0.02 0.98],[0.84 0.84], ...
    'Color',[0.4 0.4 0.4],'LineWidth',1);

text(ax2,0.02,0.76, ...
    sprintf('Predicted DR Grade: %d (%s)',predictedGrade,gradeLabel), ...
    'Color','white','FontSize',16,'FontWeight','bold', ...
    'VerticalAlignment','top');

text(ax2,0.02,0.68, ...
    sprintf('Confidence: %.2f%%',confidence * 100), ...
    'Color','white','FontSize',16, ...
    'VerticalAlignment','top');

text(ax2,0.02,0.60, ...
    sprintf('Activation Threshold: %.0f%%',threshold * 100), ...
    'Color',[0.8 0.8 0.8],'FontSize',14, ...
    'VerticalAlignment','top');

text(ax2,0.02,0.53, ...
    sprintf('Model Attention Regions: %d',numRegions), ...
    'Color',[0.8 0.8 0.8],'FontSize',14, ...
    'VerticalAlignment','top');

line(ax2,[0.02 0.98],[0.47 0.47], ...
    'Color',[0.4 0.4 0.4],'LineWidth',1);

text(ax2,0.02,0.40, ...
    {'Black boxes indicate','high-activation regions', ...
     'identified by Grad-CAM.'}, ...
    'Color','white','FontSize',13,'FontWeight','bold', ...
    'VerticalAlignment','top');

text(ax2,0.02,0.27,'Class Probabilities', ...
    'Color','white','FontSize',13,'FontWeight','bold', ...
    'VerticalAlignment','top');

probabilityY = 0.22;

for c = 1:numel(classNames)

    text(ax2,0.02,probabilityY, ...
        sprintf('Grade %d: %-18s %.2f%%', ...
        c - 1,classNames(c),probabilities(c) * 100), ...
        'Color',[0.8 0.8 0.8],'FontSize',10, ...
        'VerticalAlignment','top');

    probabilityY = probabilityY - 0.032;
end

text(ax2,0.02,0.035, ...
    'AI-assisted analysis - not a medical diagnosis.', ...
    'Color',[0.6 0.6 0.6],'FontSize',10, ...
    'VerticalAlignment','bottom');

%% 20. TITLE BAR

annotation(fig5,'textbox',[0.02 0.90 0.96 0.07], ...
    'String',sprintf( ...
    'DR Severity Analysis | Grade %d (%s) | Confidence %.2f%%', ...
    predictedGrade,gradeLabel,confidence * 100), ...
    'Color','white','FontSize',19,'FontWeight','bold', ...
    'HorizontalAlignment','center','VerticalAlignment','middle', ...
    'EdgeColor','none');

%% 21. SAVE FINAL REPORT

reportPath = fullfile( ...
    resultFolder,[imageName '_DR_Severity_Report.png']);

drawnow;

exportgraphics(fig5,reportPath,'Resolution',300);

if ~isfile(reportPath)
    error('Final DR report was not saved.');
end

fprintf('\nFinal report saved successfully:\n');
fprintf('%s\n',reportPath);

%% 22. CREATE GRAD-CAM FIGURE

fig6 = figure( ...
    'Name','Grad-CAM Analysis', ...
    'Color',[0.06 0.06 0.06], ...
    'Position',[100 50 900 850]);

ax6 = axes(fig6);

imshow(grayDisplay,'Parent',ax6);
hold(ax6,'on');

h6 = imagesc(ax6,scoreMap);
h6.AlphaData = 0.25;

colormap(ax6,jet);

if ~isempty(stats)

    areas = [stats.Area];
    [~,order] = sort(areas,'descend');
    maxRegions = min(3,numel(order));
    boxNumber = 0;

    for k = 1:maxRegions

        s = stats(order(k));

        if s.Area < 50
            continue
        end

        boxNumber = boxNumber + 1;

        rectangle(ax6, ...
            'Position',s.BoundingBox, ...
            'EdgeColor','black', ...
            'LineWidth',4);

        text(ax6, ...
            s.BoundingBox(1), ...
            max(1,s.BoundingBox(2)-5), ...
            sprintf('%d',boxNumber), ...
            'Color','white', ...
            'FontSize',14, ...
            'FontWeight','bold', ...
            'BackgroundColor','black', ...
            'Margin',2);
    end
end

axis(ax6,'image');
axis(ax6,'off');

title(ax6, ...
    sprintf('DR Severity Analysis | Grade %d (%s) | Confidence %.2f%%', ...
    predictedGrade,gradeLabel,confidence * 100), ...
    'Color','white','FontSize',18,'FontWeight','bold');

cb6 = colorbar(ax6);
cb6.Label.String = 'Grad-CAM Activation';
cb6.Label.FontSize = 12;
cb6.Color = 'white';

hold(ax6,'off');

%% 23. SAVE GRAD-CAM IMAGE

gradcamPath = fullfile( ...
    resultFolder,[imageName '_GradCAM_Analysis.png']);

drawnow;

exportgraphics(fig6,gradcamPath,'Resolution',300);

if ~isfile(gradcamPath)
    error('Grad-CAM image was not saved.');
end

fprintf('\nGrad-CAM image saved successfully:\n');
fprintf('%s\n',gradcamPath);

%% 24. FINAL CONSOLE REPORT

fprintf('\n');
fprintf('============================================\n');
fprintf('       DR REPORT GENERATION COMPLETE\n');
fprintf('============================================\n');

fprintf('Test Image        : %s\n',fileName);
fprintf('Predicted Grade   : %d (%s)\n',predictedGrade,gradeLabel);
fprintf('Confidence        : %.2f%%\n',confidence * 100);
fprintf('Attention Regions : %d\n',numRegions);

fprintf('\nClass Probabilities:\n');

for c = 1:numel(classNames)
    fprintf('Grade %d (%s): %.2f%%\n', ...
        c - 1,classNames(c),probabilities(c) * 100);
end

fprintf('\nFinal Report:\n%s\n',reportPath);
fprintf('\nGrad-CAM Analysis:\n%s\n',gradcamPath);
fprintf('\nResult Folder:\n%s\n',resultFolder);

fprintf('============================================\n');

%% 25. OPEN RESULT FOLDER

if ispc
    try
        winopen(resultFolder);
    catch
        fprintf('Could not automatically open the result folder.\n');
    end
end

%% END
