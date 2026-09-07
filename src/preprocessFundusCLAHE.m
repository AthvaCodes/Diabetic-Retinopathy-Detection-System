function processedImage = preprocessFundusCLAHE(filename)

% Read image from filename
inputImage = imread(filename);

% Convert input to double in range [0,1]
inputImage = im2double(inputImage);

% Ensure RGB image
if size(inputImage,3) == 1
    inputImage = repmat(inputImage,[1 1 3]);
end

% Extract green channel
greenChannel = inputImage(:,:,2);

% Apply CLAHE
claheImage = adapthisteq(greenChannel);

% Convert 1-channel image to 3-channel image
processedImage = cat(3, ...
    claheImage, ...
    claheImage, ...
    claheImage);

% Resize for ResNet-50
processedImage = imresize(processedImage,[224 224]);

% Prevent interpolation overshoot
processedImage = min(max(processedImage,0),1);

% Convert to single
processedImage = single(processedImage * 255);

end