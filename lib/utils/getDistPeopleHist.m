function dist = getDistPeopleHist(expidx)

p = rcnn_exp_params(expidx);

[annolistAll, imgidxs, rectidxs, rectIgnore, groupidxs]= getAnnolist(expidx);

distAll = [];
nPeople = [];
imgidxsAll = [];

for i = 1:length(imgidxs)
    fprintf('.');
    rect = annolistAll(imgidxs(i)).annorect;
    for g = 1:length(groupidxs{imgidxs(i)})
        ridxs_group = intersect(rectidxs{imgidxs(i)},groupidxs{imgidxs(i)}{g});
        if (~isempty(ridxs_group))
            dist = inf(length(ridxs_group),length(ridxs_group));
            for ridx1 = 1:length(ridxs_group)
                for ridx2 = 1:length(ridxs_group)
                    if ((ridx1 == ridx2) || ...
                            ~isfield(rect(ridxs_group(ridx1)), 'annopoints') || isempty(rect(ridxs_group(ridx1)).annopoints) || ...
                            ~isfield(rect(ridxs_group(ridx2)), 'annopoints') || isempty(rect(ridxs_group(ridx2)).annopoints))
                        continue;
                    end
                    dist(ridx1,ridx2) = util_get_min_dist(rect(ridxs_group(ridx1)),rect(ridxs_group(ridx2)));
                end
            end
            md = min(dist,[],2);
            distAll = [distAll; mean(md)];
            nPeople = [nPeople; length(ridxs_group)];
            imgidxsAll = [imgidxsAll; i];
        end
    end
    
    if (~mod(i, 100))
        fprintf(' %d/%d\n',i,length(imgidxs));
    end
end
fprintf(' done\n');

edges = 0:4:40;
[~,bin] = histc(distAll,edges);
dist = zeros(max(nPeople),length(edges));

for i = 1:length(nPeople)
    dist(nPeople(i),bin(i)+1) = dist(nPeople(i),bin(i)+1) + 1;
end

nPeopleHist = zeros(max(nPeople),1);
for i = 1:length(nPeopleHist)
    nPeopleHist(i) = sum(nPeople(nPeople == i));
end
    
figure(100); clf;

set(0,'DefaultAxesFontSize', 16)
set(0,'DefaultTextFontSize', 16)

bar3(dist);
set(gca,'XLim',[0 max(distAll)],'XTickLabel',edges);
ylabel('# people');
xlabel('avg min dist, px');
print(gcf, '-dpng', [p.plotsDir '/distPeople-expidx' num2str(expidx) '.png']);

figure(100); clf;
bar(nPeopleHist);
set(gca,'XTickLabel',1:length(nPeopleHist));
ylabel('# people');
text(0.5:length(nPeopleHist)-0.5,nPeopleHist+max(nPeopleHist)/50,num2str(nPeopleHist/sum(nPeopleHist)*100,'%1.1f'))
print(gcf, '-dpng', [p.plotsDir '/nPeople-expidx' num2str(expidx) '.png']);

    function minDist = util_get_min_dist(rect1,rect2)
        
        points1 = rect1.annopoints.point;
        points2 = rect2.annopoints.point;
        minDist = Inf;
        for idx1 = 1:length(points1)
            for idx2 = 1:length(points2)
                d = 1/rect1.scale*norm([points1(idx1).x points1(idx1).y] - [points2(idx2).x points2(idx2).y]);
                if (minDist > d)
                    minDist = d;
                end
            end
        end
        
    end

end