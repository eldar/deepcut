function vis_next_pred(joints, next_joints, graph)

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

    visJoints = false;
    if visJoints
        for jj = 1:size(joints, 1)
            %fprintf('joint %d\n', jj);
            if isnan(joints(jj, 1))
                continue;
            end
            plot(joints(jj, 1), joints(jj, 2), styles{jj}, 'MarkerSize',5);
            text(joints(jj, 1), joints(jj, 2), num2str(jj), 'Color', 'g', 'FontSize', 12);
            %pause;
        end
    end
    
    starts = [2];
    ends = [1 3 5 6 14];
    %starts = [10];
    %ends = [3 9 14 11 1];
    
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

            %if ~(start == 2 && (end_ == 1 || end_ == 3 || end_ == ))
            %    continue;
            %end
            if ~(any(start == starts) && any(end_ == ends))
                continue;
            end
            
            [~, idx] = find(ends == end_);
            color = colors{idx};

            %if ~((end_ == 7 ))
            %    continue;
            %end
            orig = joints(start, :);
            pts(1,:) = orig;
            pts(2,:) = orig + next_joints(jj,:);
            line(pts(:,1), pts(:,2), 'Color', color, 'LineWidth', 6);
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