function bboxAll= getBBoxAll(expidx,parts,N)

fprintf('getBBoxAll()\n');
p = rcnn_exp_params(expidx);
conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
predDir = [conf.cache_dir '/pred'];

for imgidx = 1:N
    bboxAll(imgidx).imgname = '';
    bboxAll(imgidx).det = cell(16,1);
end

for imgidx = 1:N
    
    fprintf('.');
    fname = [predDir '/imgidx_' padZeros(num2str(imgidx-1),5)];
    load(fname,'aboxes_nonms');
        
    assert(length(p.pidxs) == length(aboxes_nonms));
    
    for i = 1:length(p.pidxs)
        pidx = p.pidxs(i);
        % part is a joint
        assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
        jidx = parts(pidx+1).pos(1);
        bboxAll(imgidx).det{jidx+1,:} = aboxes_nonms{i}(:,1:5);
    end
    if (~mod(imgidx, 100))
        fprintf(' %d/%d\n',imgidx,length(bboxAll));
    end
end
fprintf(' done\n');
end