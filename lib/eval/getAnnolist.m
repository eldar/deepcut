function [annolistAll, imgidxsTest, rectidxs, rectIgnore, groupidxs, keypointsidxs]= getAnnolist(expidx)

p = rcnn_exp_params(expidx);
load(p.datasetInfo,'DATASET');
load(DATASET.conf.source_annolist_filename, 'annolist');
annolistAll = annolist;

if (isfield(p,'multiPeople') && p.multiPeople == true)
    for imgidx = 1:length(DATASET.single_person)
        DATASET.mult_person{imgidx} = [DATASET.mult_person{imgidx} DATASET.borderline_person{imgidx}'];
    end
    rectidxs = DATASET.mult_person;
    rectidxs_mult_subset = cell(length(DATASET.single_person),1);
    nPeople = zeros(length(DATASET.single_person),1);
    if (isfield(p,'maxPeople') && isfield(p,'minPeople'))
        for imgidx = 1:length(DATASET.single_person)
            for g = 1:length(DATASET.groups{imgidx})
                ridxs_group = intersect(rectidxs{imgidx},DATASET.groups{imgidx}{g});
                if (~isempty(ridxs_group) && length(ridxs_group) <= p.maxPeople && length(ridxs_group) >= p.minPeople)
                    rectidxs_mult_subset{imgidx} = [rectidxs_mult_subset{imgidx}; ridxs_group];
                    nPeople(imgidx) = nPeople(imgidx) + length(ridxs_group);
                end
            end
        end
    end
else
    rectidxs = DATASET.single_person;
end

groupidxs = DATASET.groups;

imgidxs1 = find(cellfun(@isempty,rectidxs) == 0);
imgidxs_test = find(DATASET.img_train == 0);
imgidxsTest = intersect(imgidxs1,imgidxs_test);
keypointsidxs = 1:length(imgidxsTest);

if (isfield(p,'maxPeople'))
    rectidxs = rectidxs_mult_subset;
    imgidxs1 = find(cellfun(@isempty,rectidxs) == 0);
    imgidxs_test = find(DATASET.img_train == 0);
    imgidxsTest2 = intersect(imgidxs1,imgidxs_test);
    keypointsidxs = find(ismember(imgidxsTest,imgidxsTest2));
    imgidxsTest = imgidxsTest2;
end

rectIgnore = cell(length(rectidxs),1);

if (isfield(p,'ignore_not_annotate') && p.ignore_not_annotate == true)
    % annotation list with all annotated people
    load('/BS/leonid-pose/work/data/new_dataset/dataset_release_candidate1/test_annolist_all_annotated_bbox','annolist');
    assert(length(annolist) == length(imgidxs_test));
    
    for imgidx = 1:length(imgidxs_test)
        rect = annolist(imgidx).annorect;
        for ridx = 1:length(rect)
            if (~isfield(rect(ridx),'annopoints') || isempty(rect(ridx).annopoints))
                rectIgnore{imgidxs_test(imgidx)} = [rectIgnore{imgidxs_test(imgidx)};[rect(ridx).x1 rect(ridx).y1 rect(ridx).x2 rect(ridx).y2]];
            end
        end
    end
end

end