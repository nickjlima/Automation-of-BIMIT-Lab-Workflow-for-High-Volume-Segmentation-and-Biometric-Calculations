% Define SSH details
sshKey = '/path/to/your-key.pem'; % Path to your private key
ec2IP = 'ec2-instance-public-ip'; % Replace with your EC2 public IP

% List of Google Drive file IDs
fileIDs = {'file-id-1', 'file-id-2', 'file-id-3', ..., 'file-id-1000'};

% Define batch size
batchSize = 50;

% Loop through batches
for batchStart = 1:batchSize:length(fileIDs)
    batchEnd = min(batchStart + batchSize - 1, length(fileIDs));
    currentBatch = fileIDs(batchStart:batchEnd);

    % Create a batch download command
    downloadCommands = "";
    for i = 1:length(currentBatch)
        googleDriveLink = sprintf('https://drive.google.com/uc?id=%s', currentBatch{i});
        downloadCommands = strcat(downloadCommands, ...
            sprintf('curl -s -o image_%d.nii.gz "%s" && ', batchStart + i - 1, googleDriveLink));
    end

    % Create a batch API call command
    processCommands = "";
    for i = 1:length(currentBatch)
        processCommands = strcat(processCommands, ...
            sprintf(['curl -s -o output_%d.zip -w "%%{http_code}" -X POST ', ...
            '-H "Content-Type: application/json" ', ...
            '-d ''{ "image": "image_%d.nii.gz", ', ...
            ' "prompts": { "classes": ["Spleen", "Liver"] } }'' ', ...
            'http://localhost:8000/v1/vista3d/inference && unzip -o output_%d.zip -d output_%d && '], ...
            batchStart + i - 1, batchStart + i - 1, batchStart + i - 1, batchStart + i - 1));
    end

    % Combine download and processing commands
    remoteCommand = strcat(downloadCommands, processCommands);

    % Construct SSH command
    sshCommand = sprintf('ssh -i %s ubuntu@%s "%s"', sshKey, ec2IP, remoteCommand);

    % Execute the SSH command via MATLAB
    [status, output] = system(sshCommand);

    % Check execution status
    if status == 0
        fprintf('Batch %d-%d processed successfully:\n', batchStart, batchEnd);
        disp(output);
    else
        warning('Batch %d-%d failed: %s', batchStart, batchEnd, output);
    end
end
