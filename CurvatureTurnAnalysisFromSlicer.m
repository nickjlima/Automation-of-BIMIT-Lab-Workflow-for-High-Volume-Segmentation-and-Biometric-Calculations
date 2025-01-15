% MATLAB script to calculate curvature, turn angles, net directions, segment lengths, and diameters
% based on coordinates extracted from a 3D Slicer file and provided volume/SA data.

% Load 3D Slicer CSV file
fileName = 'slicer_coordinates.csv'; % Replace with your 3D Slicer file name
data = readtable(fileName);

% Extract columns for R, A, S (adjust column names if necessary)
R = data.R; % Replace 'R' with the actual column name for radial coordinates
A = data.A; % Replace 'A' with the actual column name for angular coordinates
S = data.S; % Replace 'S' with the actual column name for scalar values (e.g., slice position)

% Load Volume and Surface Area Data from the document (replace with your file location)
volume_sa_file = 'RAS_points_with_SA_Vol.txt'; % Save the raw data into this file
volume_sa_data = fileread(volume_sa_file);

% Extract CS volumes and SA for each segment using regular expressions
cs_volume_matches = regexp(volume_sa_data, 'CS, mm3\):\s*(\d+\.\d+)', 'tokens');
sa_matches = regexp(volume_sa_data, 'SA \(mm2\):\s*(\d+\.\d+)', 'tokens');

% Convert extracted values to numeric arrays
cs_volumes = cellfun(@(x) str2double(x{1}), cs_volume_matches);
segment_sas = cellfun(@(x) str2double(x{1}), sa_matches);

% Initialize results
num_points = length(R);
curvatures = zeros(num_points - 2, 1);
turn_angles = zeros(num_points - 2, 1);
net_directions = strings(num_points - 2, 1);
segment_lengths = zeros(num_points - 2, 1);
diameters = zeros(num_points - 2, 1);

% Calculate curvature, turn angles, net directions, segment lengths, and diameters
for i = 1:num_points - 2
    % Points
    p1 = [R(i), S(i)];
    p2 = [R(i+1), S(i+1)];
    p3 = [R(i+2), S(i+2)];
    
    % Curvature
    numerator = abs((p2(1) - p1(1)) * (p3(2) - p1(2)) - (p3(1) - p1(1)) * (p2(2) - p1(2)));
    denominator = sqrt(((p2(1) - p1(1))^2 + (p2(2) - p1(2))^2) * ...
                       ((p3(1) - p2(1))^2 + (p3(2) - p2(2))^2) * ...
                       ((p3(1) - p1(1))^2 + (p3(2) - p1(2))^2));
    if denominator == 0
        curvatures(i) = 0;
    else
        curvatures(i) = numerator / denominator;
    end
    
    % Turn angle
    v1 = [p2(1) - p1(1), p2(2) - p1(2)];
    v2 = [p3(1) - p2(1), p3(2) - p2(2)];
    dot_product = dot(v1, v2);
    norm_product = norm(v1) * norm(v2);
    if norm_product == 0
        turn_angles(i) = 0;
    else
        turn_angles(i) = acosd(dot_product / norm_product);
    end
    
    % Net direction
    if abs(v2(1)) > abs(v2(2))
        if v2(1) > 0
            net_directions(i) = "Right";
        else
            net_directions(i) = "Left";
        end
    else
        if v2(2) > 0
            net_directions(i) = "Superior";
        else
            net_directions(i) = "Inferior";
        end
    end
    
    % Arc segment length
    segment_lengths(i) = norm(p2 - p1) + norm(p3 - p2);
    
    % Diameter (using hollow cylinder approximation)
    segment_index = ceil(i / 2); % Map i to the corresponding volume/SA index
    V = cs_volumes(segment_index);
    SA = segment_sas(segment_index);
    if segment_lengths(i) > 0
        diameters(i) = (4 * V) / (SA * pi * segment_lengths(i));
    else
        diameters(i) = NaN; % Undefined if segment length is zero
    end
end

% Create table
result_table = table((1:num_points-2)', curvatures, turn_angles, net_directions, segment_lengths, diameters, ...
                     'VariableNames', {'SegmentIndex', 'Curvature', 'TurnAngle', 'NetDirection', 'SegmentLength', 'Diameter'});

% Display table
disp(result_table);

% Save table as CSV
outputFileName = 'Curvature_Turn_Analysis_With_Diameter.csv';
writetable(result_table, outputFileName);
disp(['Results saved to ', outputFileName]);
