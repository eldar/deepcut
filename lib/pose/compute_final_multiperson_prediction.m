function people = compute_final_multiperson_prediction( dets )

num_joints = 14;

unLab = dets.unLab;

people = cell(1, 1);

idxs = unLab(:,1) < 1000;
lc_uniq = unique(unLab(idxs,2));

for j = 1:length(lc_uniq)
    lc = lc_uniq(j);
    idxsc = find(unLab(:,2) == lc);
    lp_uniq = unique(unLab(idxsc,1));

    keypoints = nan(num_joints,2);
    for i = 1:length(lp_uniq)
        lp = lp_uniq(i);
        if lp > 1000
            continue;
        end
        idxsp = find(unLab(idxsc,1) == lp);
        prob = dets.unProb(idxsc(idxsp),lp+1);
        w = prob;
        w = w./sum(w);

        loc_refine = squeeze(dets.locationRefine(idxsc(idxsp), lp+1, :));
        if size(loc_refine, 2) == 1
            loc_refine = loc_refine';
        end
        pos = sum((dets.unPos(idxsc(idxsp),:) + loc_refine).*[w w],1);

        keypoints(lp+1, :) = pos;
    end
    
    people{j} = keypoints;
end

