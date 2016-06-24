function plot_model_weights_grante(expidx)

p = rcnn_exp_params(expidx);

conf = rcnn_config('sub_dir', '/cachedir/test', 'exp_dir', [p.expDir '/' p.shortName]);
modelDir = [conf.cache_dir '/model'];
load([modelDir '/model_trained'],'model_trained');

figure(200);clf;

set(0,'DefaultAxesFontSize', 12);
set(0,'DefaultTextFontSize', 12);

for i=1:14
    subplot(2,7,i);
    w = model_trained.factor_types(i).weights;
    bar(reshape(w,4,1));
end

% figure(101);clf;
% set(0,'DefaultAxesFontSize', 12);
% set(0,'DefaultTextFontSize', 12);
% 
% for i=15:28
%     subplot(2,7,i-14);
%     bar(model_trained.factor_types(i).weights);
% end

figure(102);clf;
set(0,'DefaultAxesFontSize', 12);
set(0,'DefaultTextFontSize', 12);

% for i=29:41
for i=15:27    
    subplot(2,7,i-14);
    w = model_trained.factor_types(i).weights;
    bar(reshape(w,16,1));
end

end