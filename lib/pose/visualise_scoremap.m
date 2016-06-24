function [ scmap ] = visualise_scoremap( unary_maps, up_scale )
        if nargin < 2
            up_scale = 8;
        end

        colors = [1 0 1; 1 1 0; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; 1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; ...
                  1 0 1; 1 1 0; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1; 1 1 0; 1 0 1; 0 1 1; 1 0 0; 0 1 0; 0 0 1; 1 1 1];
        clearvars scmap;
        num_joints = size(unary_maps, 3);
        for k = 1:num_joints
            part_map = unary_maps(:,:,k);
            %imagesc(part_map);
            stuff = scoremap_to_img(part_map, colors(k, :));
            if up_scale ~= 1
                stuff = imresize(stuff, up_scale, 'bicubic');
            end
            if ~exist('scmap')
                scmap = stuff;
            else
                scmap = scmap + stuff;
            end
        end
end
