%===================================================
% Machine Vision and Cognitive Robotics (376.054)
% Exercise 4: Plane fit with RANSAC
% Daniel Wolf, Michal Staniaszek 2017
% Automation & Control Institute, TU Wien
%
% Tutors: machinevision@acin.tuwien.ac.at
%
% MAIN SCRIPT - DO NOT CHANGE CODE EXCEPT FOR THE PARAMETER SETTINGS
%===================================================
close all
clear all
clc
%%%%% CHANGE SAC PARAMETERS HERE %%%%
downsample_percent = 0.1;
% selects which single-plane file to use
pointcloud_idx = 4;            % 0-9
% Note: If you are using an older version of matlab like 2015b, using pcd
% files may not work. In this case, change the extension to 'ply'. You will
% also need to change cloud_path to 'pointclouds/ply'
cloud_path = 'pointclouds';
extension = 'pcd';

% selects which natural scene file to use
multiplane_scene = 'kitchen';

% if a plane in multiplane extraction has fewer than min_points_prop * p.Count
% points, it should be discarded and the extraction process should stop
min_points_prop = 0.03;

params = struct;
params.inlier_threshold = 0.05;      % in meters
params.min_sample_dist = 0.1;    % in meters
params.confidence = 0.90;
%params.error_func = @ransac_error;
params.error_func = @ransac_error;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% load pointcloud
p_orig = pcread(sprintf('%s/image%03d.%s',cloud_path, pointcloud_idx, extension));
p_orig = p_orig.removeInvalidPoints();

% downsample to 10% of original number of points
p_downsampled = pcdownsample(p_orig, 'random', downsample_percent);

% delete all [0;0;0] entries
p = p_downsampled.select(find(all(p_downsampled.Location ~= [0 0 0], 2)));

figure(1)
plot_pointcloud(p)
title(sprintf('Pointcloud %d', pointcloud_idx));

%% Apply ransac

sprintf('Trying to fit a plane with RANSAC...\n');

h=tic;
% Calling your function
[a,b,c,d,inliers,sample_count] = fit_plane(double(p.Location), params);
toc(h)

sprintf('DONE. %d iterations needed.\n', sample_count);

figure(2);
plot_pointcloud(p, inliers);
title(sprintf('Pointcloud %d', pointcloud_idx));

%% multi-plane extraction
p_orig = pcread(sprintf('%s/%s.%s', cloud_path, multiplane_scene, extension));
p_orig = p_orig.removeInvalidPoints();
p_downsampled = pcdownsample(p_orig, 'random', downsample_percent);
p = p_downsampled.select(find(all(p_downsampled.Location ~= [0 0 0], 2)));
[filtered, eqs, planepts] = filter_planes(double(p.Location), min_points_prop, params);

%% show multiplane results
colours = hsv(size(eqs,1)); % Colour each extracted plane differently
for plane_ind = 1:size(eqs,1)
   plane_mat = planepts{plane_ind};
   plane_mat(:, 4:6) = repmat(colours(plane_ind, :), size(plane_mat, 1), 1);
   if ~exist('coloured_mat', 'var')
       coloured_mat = plane_mat;
   else
       coloured_mat = [coloured_mat; plane_mat];
   end
end

multiplane = pointCloud([coloured_mat(:, 1:3); filtered], 'Color', [coloured_mat(:, 4:6); repmat([0.2 0.2 0.2], size(filtered,1), 1)]);
figure(3)
pcshow(multiplane)