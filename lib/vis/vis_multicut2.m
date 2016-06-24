function vis_multicut2(det,pidxs,parts)

colors = {'r','g','b','c','m','y'};
markers = {'+','o','s'}; %,'x','.','-','s','d'

for j = 1:length(det)
    labels = cell(0);
    n = 0;
    points = zeros(1,2);
    for i = 1:length(pidxs)
        pidx = pidxs(i);
        jidx = parts(pidx+1).pos(1);
        pp = det{jidx+1};
        if (~isempty(pp))
            n = n  + 1;
            labels{n} = num2str(i);
            %                     labels{n} = sprintf('%1.2f',pp(3));
            points(n,:) = pp(1:2);
        end
    end
    lp = 1;
    if (lp <= 5)
        m = markers{1};
    elseif (lp > 5 && lp <= 11)
        m = markers{2};
    else
        m = markers{3};
    end
    plot(points(:,1),points(:,2),[colors{mod(lp,6)+1} m],'MarkerSize',5);
    text(points(:,1)+10,points(:,2),labels,'FontSize',6,'BackgroundColor','w');
    axis off;
end

end