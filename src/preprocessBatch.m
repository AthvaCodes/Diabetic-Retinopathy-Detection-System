function output = preprocessBatch(data)

    % ============================================================
    % PREPROCESS A SINGLE IMAGE OR A MINI-BATCH
    % ============================================================

    if iscell(data)

        % Number of images in the batch
        numImages = numel(data);

        processedImages = cell(numImages, 1);

        for i = 1:numImages

            processedImages{i} = ...
                preprocessFundusCLAHE(data{i});

        end

        % Convert images into:
        % Height x Width x Channels x Batch

        imageBatch = cat(4, processedImages{:});

    else

        % Single image

        imageBatch = preprocessFundusCLAHE(data);

        % Add batch dimension

        imageBatch = reshape(imageBatch, ...
            size(imageBatch,1), ...
            size(imageBatch,2), ...
            size(imageBatch,3), ...
            1);

    end


    % ============================================================
    % IMPORTANT
    % CombinedDatastore expects cell output
    % ============================================================

    output = {imageBatch};

end