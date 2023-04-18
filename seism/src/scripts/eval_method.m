% function eval_method(method, parameter, measure, read_part_fun, database, gt_set, num_params, segm_or_contour)
% ------------------------------------------------------------------------ 
%  Copyright (C)
%  Universitat Politecnica de Catalunya BarcelonaTech (UPC) - Spain
% 
%  Jordi Pont-Tuset <jordi.pont@upc.edu>
%  June 2013
% ------------------------------------------------------------------------ 
%  File part of the code 'segmentation_evaluation', from the paper:
%
%  Jordi Pont-Tuset, Ferran Marques,
%  "Measures and Meta-Measures for the Supervised Evaluation of Image Segmentation,"
%  Computer Vision and Pattern Recognition (CVPR), 2013.
% ------------------------------------------------------------------------
function eval_method(method, parameter, measure, read_part_fun, database, gt_set, num_params, segm_or_contour, cat_ids)

if ~exist('segm_or_contour','var')
    segm_or_contour = 0;
end

% I/O folders
method_dir = fullfile(seism_root,'datasets',database,method);
res_dir    = fullfile(seism_root,'results' ,database,method);

kill_internal = 0;
if strcmp(database,'Pascal'),
    maxDist = 0.01;
elseif strcmp(database,'SBD'),
    maxDist = 0.02;
    kill_internal = 1;
    method_dir = fullfile(seism_root,'datasets',database,method,num2str(cat_ids));
    res_dir    = fullfile(seism_root,'results' ,database,method,num2str(cat_ids));
elseif strcmp(database,'PASCALContext'),
    maxDist = 0.0075;
elseif strcmp(database,'NYUD'),
    maxDist = 0.011;
else
    maxDist = 0.0075;
end

% Load indices
im_ids = db_ids(database, gt_set);


if ~exist(res_dir,'dir')
    mkdir(res_dir)
end
results_file = fullfile(res_dir, [gt_set '_' measure '_' parameter '.txt']);

% Leave as is if already computed, but check that it's complete,
% in case an execution before broke
if exist(results_file,'file')
    % Check not empty
    s = dir(results_file);
    if s.bytes > 0
        tmp = dlmread(results_file,',');
        if size(tmp,1)==length(im_ids)
            disp(['Already computed: ' results_file])
            return;
        end
    end;
end

% Open results file
fid_results = fopen(results_file, 'w');
if(fid_results==-1)
    error(['Error: results file not writable: ' results_file])
else
    disp(['Computing: ' results_file])
end

% Run on all images
for ii=1:numel(im_ids)
    % Display evolution      
    % disp([num2str(ii) ' out of ' num2str(numel(im_ids))])
    curr_id = im_ids{ii};

    % Read ground truth (gt_seg)
    lkup = [];
    if strcmp(database,'SBD'),
        [gt_seg,~,~,~,lkup] = db_gt(database,curr_id,'cls',cat_ids);
    else
        gt_seg = db_gt(database,curr_id);
    end
    % Read the partition
    partition_or_contour = read_part_fun(method_dir, parameter, num2str(curr_id));

    % Check that we have the partition or contour
    if isempty(partition_or_contour)
        error(['Missing result ' num2str(curr_id) '_' parameter])
    end
    
    % Rotate if necessary (different image)
    if ~isequal(size(gt_seg{1}), size(partition_or_contour))
        partition_or_contour = imrotate(partition_or_contour,90);
    end
    
    % Compute measure
    if segm_or_contour==0 % Segmentation
        value = eval_segm(partition_or_contour,gt_seg,measure, maxDist, kill_internal, lkup);
    else % Contour
        if ~strcmp(measure,'fb')
            error('Contours can only be evaluated using the ''fb'' measure')
        end
        value = eval_cont(partition_or_contour, gt_seg, maxDist, kill_internal,lkup);
    end
    
    % Write to file
    for jj=1:length(value)-1
        fprintf(fid_results, '%f\t', value(jj));
    end
    fprintf(fid_results, '%f\n', value(end));
end

fclose(fid_results);

