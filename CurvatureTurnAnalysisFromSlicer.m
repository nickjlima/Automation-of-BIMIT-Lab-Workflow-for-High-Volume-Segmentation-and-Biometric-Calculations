% MATLAB script to calculate curvature, turn angles, net directions, and segment lengths
% based on coordinates extracted from a 3D Slicer file.

% Load 3D Slicer CSV file
fileName = 'slicer_coordinates.csv'; % Replace with your 3D Slicer file name
data = readtable(fileName);

% Extract columns for R, A, S (adjust column names if necessary)
R = data.R; % Replace 'R' with the actual column name for radial coordinates
A = data.A; % Replace 'A' with the actual column name for angular coordinates
S = data.S; % Replace 'S' with the actual column name for scalar values (e.g., slice position)

% Initialize results
num_points = length(R);
curvatures = zeros(num_points - 2, 1);
turn_angles = zeros(num_points - 2, 1);
net_directions = strings(num_points - 2, 1);
segment_lengths = zeros(num_points - 2, 1);

% Calculate curvature, turn angles, net directions, and segment lengths
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
    
    % Segment length
    segment_lengths(i) = norm(p2 - p1) + norm(p3 - p2);
end

% Create table
result_table = table((1:num_points-2)', curvatures, turn_angles, net_directions, segment_lengths, ...
                     'VariableNames', {'SegmentIndex', 'Curvature', 'TurnAngle', 'NetDirection', 'SegmentLength'});

% Display table
disp(result_table);

% Save table as CSV
outputFileName = 'Curvature_Turn_Analysis_Table.csv';
writetable(result_table, outputFileName);
disp(['Results saved to ', outputFileName]);
