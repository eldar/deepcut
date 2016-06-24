function [ dets ] = split_detections_by_probabilities( dets, p, cidxs )

num_dets = size(dets.unProb, 1);
thresh = p.split_threshold;

idxs = [];
to_suppress = cell(0, 1);

unProb = dets.unProb;

det_cout = 0;

for k = 1:num_dets
    high_scores = [];
    for c = cidxs
        if unProb(k, c) >= thresh
            high_scores = [high_scores; c];
        end
    end
    if length(high_scores) > 1 % split
        for i = 1:length(high_scores)
            c = high_scores(i);
            to_suppress_local = high_scores;
            to_suppress_local(to_suppress_local == c) = [];
            idxs = [idxs k];
            det_cout = det_cout + 1;
            to_suppress{det_cout} = to_suppress_local;
        end
    else
        idxs = [idxs k];
        det_cout = det_cout + 1;
        to_suppress{det_cout} = [];
    end
end

dets = Detections.slice(dets, idxs);
for k = 1:size(dets.unProb, 1)
    to_suppress_local = to_suppress{k};
    for cidx = to_suppress_local
        dets.unProb(k, cidx) = 0;
    end
end


end

