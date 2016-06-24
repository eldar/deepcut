function [net_file, last_iter] = get_net_filename(netsDir)

final_file = [netsDir '/final_model.caffemodel'];

if exist(final_file, 'file') == 2
    net_file = final_file;
    return;
end

files = dir([netsDir '/finetune_train_iter_*']);
last_iter = -inf;
bestIdx = -1;
for i=1:length(files)
    filename = files(i).name;
    [~,name,ext] = fileparts(filename);
    if strcmp(ext, '.caffemodel')
        filename = name;
    end
    j = strfind(filename,'_');
    iter = str2num(filename(j(end)+1:end));
    if (last_iter < iter)
        last_iter = iter;
        bestIdx = i;
    end
end

net_file = '';
if (bestIdx > -1)
    net_file     = [netsDir '/' files(bestIdx).name];
end

end