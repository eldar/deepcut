num = 1000;
radius = 17;
%{
angle = rand(num, 1) * 2* pi;
distance = rand(num, 1) * radius;
xs = cos(angle).* distance;
ys = sin(angle).* distance;
%}

t = 2*pi*rand(num, 1);
u = rand(num, 1)+rand(num, 1);
r = zeros(num, 1);
r(u>1) = 2-u(u>1);
r(u<=1) = u(u<=1);
xs = r.*cos(t)*radius;
ys = r.*sin(t)*radius;

[q1,q2] = meshgrid(1:num,1:num);
idxs = [q1(:) q2(:)];
dists = sqrt((xs(idxs(:,1))-xs(idxs(:,2))).^2 + (ys(idxs(:,1))-ys(idxs(:,2))).^2);

figure(1);
scatter(xs, ys);
figure(2);
histogram(dists);

xs = 0:35;
ys = exp(-0.0000015*xs.^4);
%ys = exp(-0.0001*xs.^3);
figure(3);
plot(xs, ys);

        
        %{
        if false
            for cidx=8:8
                num = 200;
                radius = 70;
                t = 2*pi*rand(num, 1);
                u = rand(num, 1)+rand(num, 1);
                r = zeros(num, 1);
                r(u>1) = 2-u(u>1);
                r(u<=1) = u(u<=1);
                xs2 = r.*cos(t)*radius;
                ys2 = r.*sin(t)*radius;
                dists = sqrt(xs2.^2+ys2.^2);
                xs2 = [0; xs2];
                ys2 = [0; ys2];
                boxes2 = [xs2-half_size, ys2-half_size, xs2+half_size, ys2+half_size];
                idxsSameAll2 = zeros(num, 2);
                idxsSameAll2(:,1) = 2:num+1;
                idxsSameAll2(:,2) = 1;
                [featSame2,~,~,~] = get_spatial_features_same_img(boxes2,idxsSameAll2);
                lab2 = zeros(size(featSame2, 1), 1);
                feat_norm2 = getFeatNorm(featSame2,rcnn_model.training_opts(cidx).X_min,rcnn_model.training_opts(cidx).X_max);
                % compute pairwise prob
                ex2 = sparse(double(feat_norm2));
                [~,~,prob] = predict(lab2, ex2, rcnn_model.log_reg(cidx), '-b 1');
                figure(40+cidx);
                scatter(dists, prob(:,1));
                xs = 0:radius;
                %ys = exp(-0.0000015*xs.^4);
                ys = 1./(1+exp(0.2*xs-7.5));
                figure(5);
                plot(xs, ys);
            end
            pause;
        end
        %}