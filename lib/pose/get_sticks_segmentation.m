function [ scmap_all,poly ] = get_sticks_segmentation( p, im, joints )

stride = 4; %p.stride;
half_stride = stride/2;
scale_factor = p.scale_factor;
sz = 17;

scmap_height = ceil(size(im, 1) * scale_factor / stride);
scmap_width = ceil(size(im, 2) * scale_factor / stride);

joint_pairs = [1 2; 2 3; 6 5; 4 5; 7 8; 8 9; 12 11; 11 10; 13 14];
limb_size_coefs = [1.0 1.0 1.0 1.0 0.8 0.8 0.8 0.8 1.0];

num_sticks = size(joint_pairs, 1) + 1;

scmap_all = zeros(scmap_height, scmap_width, num_sticks);

for k = 1:size(joint_pairs, 1)
    scmap = zeros(scmap_height, scmap_width);
    limb_sz = sz * limb_size_coefs(k);

    jnt1 = joints(joint_pairs(k, 1), :);
    jnt2 = joints(joint_pairs(k, 2), :);
    if ~isnan(jnt1(1)) && ~isnan(jnt2(1))

        % stick heatmap
        diff = jnt2-jnt1;
        if norm(diff) > 1.0
            perp = [-diff(2) diff(1)];
            perp = perp/norm(perp);
            % construct stick polygon
            poly = zeros(5, 2, 'double');
            poly(1,:) = jnt1-perp*limb_sz;
            poly(2,:) = jnt1+perp*limb_sz;
            poly(3,:) = jnt2+perp*limb_sz;
            poly(4,:) = jnt2-perp*limb_sz;
            poly(5,:) = poly(1,:);

            for j = 1:scmap_height
                for i = 1:scmap_width

                    crd = [i-1, j-1]*stride;
                    if p.res_net
                        crd = crd + half_stride;
                    end
                    crd = single(crd)/scale_factor;
                    [in, on] = inpolygon(crd(1),crd(2),poly(:,1),poly(:,2));
                    scmap(j, i) = in | on;
                end
            end

            if k ~= 9
                for j = 1:scmap_height
                    for i = 1:scmap_width

                        crd = [i-1, j-1]*stride;
                        if p.res_net
                            crd = crd + half_stride;
                        end
                        crd = single(crd)/scale_factor;

                        if norm(crd-jnt1) <= limb_sz
                            scmap(j, i) = 1;
                        end
                        if norm(crd-jnt2) <= limb_sz
                            scmap(j, i) = 1;
                        end
                    end
                end
            end
        end
    end
     
    scmap_all(:,:,k) = scmap(:,:);
end

% torso
jnt = zeros(4, 2);
joints = int32(joints);
jnt1 = double(joints(3, :));
jnt2 = double(joints(4, :));
jnt3 = double(joints(9, :));
jnt4 = double(joints(10, :));

if ~isnan(jnt1(1)) && ~isnan(jnt2(1)) && ~isnan(jnt3(1)) && ~isnan(jnt4(1))
    points = zeros(1, 2);
    
    index = 1;
    
    if all(jnt1 == jnt2)
        jnt2(1) = jnt1(1) + 1;
    end
    diff12 = normalise(jnt2-jnt1);
    points(index, :) = jnt2 + diff12*sz;
    index = index + 1;
    points(index, :) = jnt1 - diff12*sz;
    index = index + 1;

    if all(jnt1 == jnt3)
        jnt3(2) = jnt1(2) - 1;
    end
    diff13 = normalise(jnt3-jnt1);
    points(index, :) = jnt3 + diff13*sz;
    index = index + 1;
    points(index, :) = jnt1 - diff13*sz;
    index = index + 1;

    if norm(jnt3 - jnt4) <= sz*1.5
        if all(jnt4 == jnt3)
            jnt4(1) = jnt3(1) + 1;
        end

        diff34 = normalise(jnt4-jnt3);
        points(index, :) = jnt4 + diff34*sz;
        index = index + 1;
        points(index, :) = jnt3 - diff34*sz;
        index = index + 1;
    end

    if all(jnt2 == jnt4)
        jnt4(2) = jnt2(2) - 1;
    end
    diff24 = normalise(jnt4-jnt2);
    points(index, :) = jnt4 + diff24*sz;
    index = index + 1;
    points(index, :) = jnt2 - diff24*sz;
    index = index + 1;
    
    I = convhull(points(:,1), points(:, 2));
    poly = points(I, :);
    
    scmap = zeros(scmap_height, scmap_width);
    for j = 1:scmap_height
        for i = 1:scmap_width

            crd = [i-1, j-1]*stride;
            if p.res_net
                crd = crd + half_stride;
            end
            crd = single(crd)/scale_factor;
            [in, on] = inpolygon(crd(1),crd(2),poly(:,1),poly(:,2));
            scmap(j, i) = in | on;
        end
    end
    
    scmap_all(:,:,size(scmap_all, 3)) = scmap(:,:);
end


end

function out = normalise(vec)
vec = double(vec);
n = norm(vec);
if n <= 1
end
out = vec/norm(vec);
end