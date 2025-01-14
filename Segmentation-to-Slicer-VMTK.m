% Define SSH details
sshKey = '/path/to/your-key.pem'; % Path to your private key
ec2IP = 'your-ec2-public-ip'; % Replace with your EC2 public IP
localSaveFolder = 'ProcessedResults'; % Local folder for saving processed results
remoteSegmentationFolder = '~/segmentations'; % Folder on EC2 for segmentations
remoteBaseImageFolder = '~/base_images'; % Folder on EC2 for base images
remoteOutputFolder = '~/processed_results'; % Folder on EC2 for processed outputs

% Ensure local save folder exists
if ~exist(localSaveFolder, 'dir')
    mkdir(localSaveFolder);
end

% Step 1: Generate processing commands for EC2
slicerScriptPath = '~/extract_centerline.py'; % Path to Slicer Python script on EC2
vmtkCommandBase = 'vmtkcenterlineviewer';

% Define segmentation and base image file list
segmentations = dir(fullfile(localSaveFolder, '*.nii.gz'));
baseImages = dir(fullfile(localSaveFolder, '*.nii.gz'));

% Loop through each file and process them remotely
for i = 1:length(segmentations)
    segmentationFileName = segmentations(i).name;
    baseImageFileName = baseImages(i).name;
    
    % Define remote file paths
    remoteSegmentationFile = fullfile(remoteSegmentationFolder, segmentationFileName);
    remoteBaseImageFile = fullfile(remoteBaseImageFolder, baseImageFileName);
    slicerOutputFile = fullfile(remoteOutputFolder, sprintf('centerline_%d.vtp', i));
    vmtkCSVOutputFile = fullfile(remoteOutputFolder, sprintf('centerline_metrics_%d.csv', i));
    
    % Generate Slicer command
    slicerCommand = sprintf(...
        '/path/to/Slicer --no-main-window --python-script %s --segmentation %s --base-image %s --output %s', ...
        slicerScriptPath, remoteSegmentationFile, remoteBaseImageFile, slicerOutputFile);
    
    % Generate VMTK command
    vmtkCommand = sprintf('%s -ifile %s -ofile %s', ...
        vmtkCommandBase, slicerOutputFile, vmtkCSVOutputFile);
    
    % Combine into a single remote command
    remoteCommand = sprintf('%s && %s', slicerCommand, vmtkCommand);
    
    % Construct SSH command to execute on EC2
    sshCommand = sprintf('ssh -i %s ubuntu@%s "%s"', sshKey, ec2IP, remoteCommand);
    
    % Execute SSH command
    [status, output] = system(sshCommand);
    
    % Check for errors
    if status == 0
        fprintf('Successfully processed %s on EC2.\n', segmentationFileName);
    else
        warning('Failed to process %s. Error: %s', segmentationFileName, output);
    end
    
    % Step 2: Download results to local machine
    scpCommand = sprintf('scp -i %s ubuntu@%s:%s/* %s', ...
        sshKey, ec2IP, remoteOutputFolder, localSaveFolder);
    [scpStatus, scpOutput] = system(scpCommand);
    
    if scpStatus == 0
        fprintf('Results for %s downloaded to %s.\n', segmentationFileName, localSaveFolder);
    else
        warning('Failed to download results for %s. Error: %s', segmentationFileName, scpOutput);
    end
end

disp('Processing completed for all files.');
