function tompson2keypointsAll(expidx)

p = rcnn_exp_params(expidx);

src_pred = load('~/src/eval_lsp/pred/tompson14/pred_keypoints_lsp_pc_14.mat');
keypointsAll = struct;
idxs = [1:6, 11:16, 9:10];

imdb = exp2imdb(expidx, 'test');

for i = 1:1000
    keypointsAll(i,1).imgname = imdb.image_at(i);
    det = ones(16, 3);
    det(7:8,:)= NaN;
    for j = 1:14
        pt = src_pred.pred(:, j, i);
        pt = pt * (2*225/150) + [100; 100];
        idx = idxs(j);
        det(idx, 1:2) = pt;
    end
    keypointsAll(i,1).det = det;
end
save(p.evalTest, 'keypointsAll');