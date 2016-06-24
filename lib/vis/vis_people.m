function vis_people( expidx, firstidx, nImgs)

if (nargin < 3)
    nImgs = 1;
end

colors = {'r','g','b','c','m','y'};
markerSize = 6;
lineWidth = 4;
edges = [1 2; 2 3; 3 13; 4 13; 4 5; 5 6; 7 8; 8 9; 10 11; 11 12; 9 13; 10 13; 13 14];

p = exp_params(expidx);
load(p.testGT,'annolist');

lastidx = firstidx+nImgs-1;

figure;

for imgidx = firstidx:lastidx

    imgname = annolist(imgidx).image.name;
    img = imread(imgname);

    clf;
    imagesc(img); axis equal; hold on;
    
    load([p.multicutDir '/prediction_' padZeros(num2str(imgidx),4)], 'people');

    for j = 1:length(people)
        person = people{j};
        person_color = colors{mod(j-1,6)+1};

        for i = 1:size(edges,1)
            pos1 = person(edges(i,1), :);
            pos2 = person(edges(i,2), :);
            if (~isnan(pos1(1)) && ~isnan(pos2(1)))
                plot([pos1(1);pos2(1)],[pos1(2);pos2(2)],[person_color '-'],'linewidth',lineWidth);
            end
        end

        for i = 1:size(person, 1)
            if isnan(person(i, 1))
                continue;
            end
            pos = person(i, :);
            cp = colors{mod(i-1,6)+1};
            plot(pos(:,1),pos(:,2),[cp 'o'],'MarkerSize',markerSize,'MarkerFaceColor',cp,'MarkerEdgeColor','k');
        end

    end
end

end

