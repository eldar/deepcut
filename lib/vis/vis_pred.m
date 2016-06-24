function vis_pred(joints, next_joints, graph)

    if nargin < 3
        next_joints = [];
    end
    
    colors = {'r','g','b','c','m','y'};
    markers = {'+','o','s', 'x','.'}; %,'-','s','d'};
    styles = {};
    j = 1;
    for m = 1:length(markers)
        for c = 1:length(colors)
            styles{j} = [colors{c} markers{m}];
            j = j + 1;
        end
    end

    axis equal; hold on;
    
    for jj = 1:size(joints, 1)
        %fprintf('joint %d\n', jj);
        if isnan(joints(jj, 1))
            continue;
        end
        plot(joints(jj, 1), joints(jj, 2), styles{jj}, 'MarkerSize',5);
        text(joints(jj, 1), joints(jj, 2), num2str(jj), 'Color', 'g', 'FontSize', 12);
        %pause;
    end
    
    bVisSkeleton = false;
    if bVisSkeleton
        skeleton = [1 2; 2 3; 7 8; 8 9; 6 5; 5 4; 12 11; 11 10; 13 14];
        for jj = 1:size(skeleton, 1)
            v1 = skeleton(jj, 1);
            v2 = skeleton(jj, 2);
            pts(1,:) = joints(v1, :);
            pts(2,:) = joints(v2, :);
            if jj <= 4
                c = 'r';
            elseif jj <= 8
                c = 'b';
            else
                c = 'g';
            end
            line(pts(:,1), pts(:,2), 'Color', c, 'LineWidth', 2);
        end
    end
    
    
    if ~isempty(next_joints)
        %{
        for jj = 1:size(next_joints, 1)
            pts = zeros(2,2);
            pts(1,:) = joints(jj, :);
            pts(2,:) = joints(jj, :) + next_joints(jj,:);
            line(pts(:,1), pts(:,2), 'Color', 'r');
        end
        %}

        for jj = 1:size(next_joints, 1)
            pts = zeros(2,2);
            start = graph(jj, 1);
            end_  = graph(jj, 2);

            if ~(start == 2 && (end_ == 1 || end_ == 2))
                continue;
            end

            %if ~((end_ == 7 ))
            %    continue;
            %end
            orig = joints(start, :);
            pts(1,:) = orig;
            pts(2,:) = orig + next_joints(jj,:);
            line(pts(:,1), pts(:,2), 'Color', 'r', 'LineWidth', 2);
            %{
            if jj <= 13
                line(pts(:,1), pts(:,2), 'Color', 'b');
            else
               line(pts(:,1), pts(:,2), 'Color', 'r');
            end
            %}
        end
    end
end