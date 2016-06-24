function issingle = getSinglePersonImages(annolist_all)

load('/BS/leonid-pose/work/data/new_dataset/dataset_release_candidate1/test_annolist_all_annotated','annolist');
load('/home/andriluk/IMAGES/human_pose_dataset/dataset/dataset_release_candidate1/dataset_info_v12');
imgidxs = find(DATASET.img_train == 0);

names = cell(length(annolist),1);
idxs = [];
for imgidx = 1:length(annolist)
    if (isfield(annolist(imgidx),'annorect') && length(annolist(imgidx).annorect) == 1)
        names{imgidx} = ['im' padZeros(num2str(imgidxs(imgidx)),5)];
        idxs = [idxs; imgidx];
    end
end

names = names(idxs);

issingle = zeros(length(annolist_all),1);
for imgidx = 1:length(annolist_all)
    [~,n] = fileparts(annolist_all(imgidx).image.name);
    issingle(imgidx) = ~isempty(find(strcmp(names,n(1:7))));
end

% assert(length(names) == sum(idxs));

end