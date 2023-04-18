% ------------------------------------------------------------------------
%  Copyright (C)
%  ETHZ - Computer Vision Lab
%
%  Jordi Pont-Tuset <jponttuset@vision.ee.ethz.ch>
%  September 2015
% ------------------------------------------------------------------------
% This file is part of the BOP package presented in:
%    Pont-Tuset J, Van Gool, Luc,
%    "Boosting Object Proposals: From Pascal to COCO"
%    International Conference on Computer Vision (ICCV) 2015.
% Please consider citing the paper if you use this code.
% ------------------------------------------------------------------------
function [ground_truth, gt_set, im, anns, matches_lookup] = db_gt( database, image_id, ptype, cat_ids )

if nargin<3,
    ptype = 'inst'; % Instance partitions by default, 'cls' for class.
end
if nargin<4,
    cat_ids = 1:20; % All categories by default
end

% Check the folder exists
if ~exist(db_root_dir(database),'dir')
    error(['Database roor dir ''' db_root_dir(database) ''' not found']);
end


if strcmp(database,'Pascal')
    % Load Object and Class ground truth
    gt_cls  = imread(fullfile(db_root_dir(database), 'SegmentationClass', [image_id '.png']));
    gt = zeros(size(gt_cls));
    if strcmp(ptype,'cls'),
        for i=1:length(cat_ids),
            gt(gt_cls==cat_ids(i)) = cat_ids(i);
        end
    elseif strcmp(ptype,'inst'),
        gt_inst = imread(fullfile(db_root_dir(database), 'SegmentationObject', [image_id '.png']));
        obj_ids   = unique(gt_inst);
        obj_ids(obj_ids==0) = [];
        obj_ids(obj_ids==255) = [];
        for ii=1:length(obj_ids)
            mask   = (gt_inst==obj_ids(ii));
            category = gt_cls(find(mask==1,1,'first'));
            if ismember(category,cat_ids),
                gt(gt_inst==obj_ids(ii))=ii;
            end
        end
    end
    ground_truth = {relabel(uint32(gt))};
    
elseif strcmp(database,'SBD')
    gt_cls = loadvar(fullfile(db_root_dir(database), 'cls', [image_id '.mat']),'GTcls');
    gt = zeros(size(gt_cls.Segmentation));
    
    if strcmp(ptype,'inst'),
        gt_inst= loadvar(fullfile(db_root_dir(database), 'inst', [image_id '.mat']),'GTinst');
        obj_num = length(gt_inst.Boundaries);
        for ii=1:obj_num
            mask   = (gt_inst.Segmentation==ii);
            category = gt_cls.Segmentation(find(mask==1,1,'first'));
            if ismember(category,cat_ids),
                gt(gt_inst.Segmentation==ii)=ii;
            end
        end
    elseif strcmp(ptype, 'cls'),
        for i=1:length(cat_ids),
            gt(gt_cls.Segmentation==cat_ids(i)) = cat_ids(i);
        end
    else
        error('Something went wrong. Check curr_eval.');
    end
    gt = relabel(gt);
    for ii=1:length(unique(gt)),
        mask   = (gt==ii);
        category = gt_cls.Segmentation(find(mask==1,1,'first'));
        matches_lookup(ii,1:2) = [ii, category]; % Store Segment - Category labels
    end
    ground_truth = {gt};
    gt_set=[]; im=[]; anns=[];
elseif strcmp(database,'COCO')
    
    % Look for the image in the subfodlers to get gt_set
    folds = dir(fullfile(db_root_dir(database),'images'));
    gt_set = '';
    for ii=1:length(folds)
        if (folds(ii).isdir && folds(ii).name(1)~='.')
            if exist(fullfile(db_root_dir(database), 'images', folds(ii).name, [image_id '.jpg']),'file')
                gt_set = folds(ii).name;
                break;
            end
        end
    end
    if strcmp(gt_set,'')
        error(['Image not found: ' image_id ' in ' db_root_dir(database)]);
    end
    
    % Get image to know the size
    im = imread(fullfile(db_root_dir(database), 'images', gt_set, [image_id '.jpg']));
    
    % Include the COCO API
    addpath(fullfile(db_root_dir('COCO'),'coco_api','MatlabAPI'));
    
    % Get COCO api for instance annotations (we store it to the 'base'
    % workspace to avoid having to read it every time)
    annFile = fullfile(db_root_dir('COCO'),'annotations',['instances_' gt_set '.json']);
    if ~evalin('base',['exist(''coco_' gt_set ''',''var'')'])
        disp(['Loading ' annFile])
        evalin('base',['coco_' gt_set '=CocoApi(''' annFile ''');']);
    end
    coco = evalin('base', ['coco_' gt_set]);
    
    % Extract the image number out of the id
    undersc = strfind(image_id,'_');
    assert(length(undersc)==2);
    im_id  = str2double(image_id(undersc(2)+1:end));
    annIds = coco.getAnnIds('imgIds',im_id,'iscrowd',0);
    anns   = coco.loadAnns(annIds);
    
    % Get the masks and categories for that image
    for ii=1:length(anns)
        ground_truth.masks{ii} = MaskApi.decode(MaskApi.frPoly(anns(ii).segmentation,size(im,1),size(im,2)))>0;
        ground_truth.boxes{ii} = round([anns(ii).bbox(2) anns(ii).bbox(1) anns(ii).bbox(2)+anns(ii).bbox(4) anns(ii).bbox(1)+anns(ii).bbox(3)]);
        ground_truth.boxes{ii}(ground_truth.boxes{ii}<=0) = 1;
        if(ground_truth.boxes{ii}(3)>size(im,1))
            ground_truth.boxes{ii}(3) = size(im,1);
        end
        if(ground_truth.boxes{ii}(4)>size(im,2))
            ground_truth.boxes{ii}(4) = size(im,2);
        end
        ground_truth.category(ii) = anns(ii).category_id;
        ground_truth.obj_id(ii)   = anns(ii).id;
        ground_truth.im_id{ii}    = image_id;
    end
    
    % Handle empty case
    if ~exist('ground_truth','var')
        ground_truth.masks    = {};
        ground_truth.boxes    = {};
        ground_truth.category = [];
        ground_truth.obj_id   = [];
        ground_truth.im_id    = {};
    end
    
    % All valid pixels (to make it compatible with SBD and Pascal)
    ground_truth.valid_pixels = true(size(im,1),size(im,2));
    
elseif strcmp(database,'bsds_object_gt')
    
    % Load file
    gt_inst = loadvar(fullfile(db_root_dir(database), 'groundTruth', [image_id '_gt.mat']),'objmask');
    
    % Transform ground truth into separate masks
    obj_ids   = unique(gt_inst);
    obj_ids(obj_ids==0) = [];
    for ii=1:length(obj_ids)
        ground_truth.masks{ii} = (gt_inst==obj_ids(ii));
        ground_truth.category(ii) = 1;
        ground_truth.obj_id(ii)   = ii;
        ground_truth.im_id{ii}    = image_id;
    end
    
    % Handle empty case
    if isempty(obj_ids)
        ground_truth.masks = {};
        ground_truth.boxes    = {};
        ground_truth.category = [];
        ground_truth.obj_id   = [];
        ground_truth.im_id    = [];
    end
    
    % Valid pixels (to make it compatible with SBD and Pascal)
    ground_truth.valid_pixels = (gt_inst<255);
elseif strcmp(database,'BSDS500')
    % Look for the file
    if exist(fullfile(db_root_dir(database), 'data', 'groundTruth', 'train', [image_id '.mat']),'file')
        gt = loadvar(fullfile(db_root_dir(database), 'data', 'groundTruth', 'train', [image_id '.mat']),'groundTruth');
    elseif exist(fullfile(db_root_dir(database), 'data', 'groundTruth', 'val', [image_id '.mat']),'file')
        gt = loadvar(fullfile(db_root_dir(database), 'data', 'groundTruth', 'val', [image_id '.mat']),'groundTruth');
    elseif exist(fullfile(db_root_dir(database), 'data', 'groundTruth', 'test', [image_id '.mat']),'file')
        gt = loadvar(fullfile(db_root_dir(database), 'data', 'groundTruth', 'test', [image_id '.mat']),'groundTruth');
    else
        error(['Ground truth for image ' image_id ' not found in ' fullfile(db_root_dir(database), 'data', 'groundTruth')]);
    end
    
    % Store it as cell of partitions
    ground_truth = cell(1,length(gt));
    for jj=1:length(gt)
        ground_truth{jj} = uint32(gt{jj}.Segmentation);
    end
elseif strcmp(database,'PASCALContext')
    gt = loadvar(fullfile(db_root_dir(database), 'trainval', [image_id '.mat']),'LabelMap');
    ground_truth = {relabel(uint32(gt))};
elseif strcmp(database,'NYUD') 
    gt = imread(fullfile(db_root_dir(database), 'edge', [image_id '.png']));
    ground_truth = {uint32(gt)};
else
    error(['Ground truth not implemented for: ' database]);
end
end
