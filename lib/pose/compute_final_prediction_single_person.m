function [detAll, pts] = compute_final_prediction_single_person(p, annolist, imgidx, crop, dets, scoremaps, locref_pred)
    unPos = dets.unPos;
    unProb = dets.unProb;
    locationRefine = dets.locationRefine;
    unLab = dets.unLab;
    
    %[~,parts] = util_get_parts24();
    parts = get_parts();
    cidxs = p.cidxs_full;
    num_joints = length(cidxs);

    locref = p.locref;
    if (isfield(p,'all_parts_on'))
        bAllPartsOn = p.all_parts_on;
    else
        bAllPartsOn = false;
    end

    detAll = nan(16,3);
    pts = zeros(num_joints, 2);

    img = imread(annolist(imgidx).image.name);
    [Y,X,~] = size(img);
    Y = 0.5*Y; X = 0.5*X;
    
    for i = 1:length(p.pidxs)
        if (~ismember(i,cidxs))
            continue;
        end
        pidx = p.pidxs(i);
        assert(parts(pidx+1).pos(1) == parts(pidx+1).pos(2));
        jidx = parts(pidx+1).pos(1);
                
%         detidxs = find(unLab(:,1) == i-1);
        detidxs = find(unLab(:,1) == find(cidxs == i)-1);
        if (isempty(detidxs))
            if (bAllPartsOn)
                cidx = find(cidxs == i);
                part_map = scoremaps(:,:,cidx);

                [~,I] = max(part_map(:));
                [row, col] = ind2sub(size(part_map),I);
                
                det = scoremap_to_coord(p, [col row], crop, locref_pred(row, col, cidx));
            else
                det = [inf inf];
            end
        else
            clusidxs = unLab(detidxs,2);
            clusidxsUniq = unique(clusidxs);
            nExClus = zeros(length(clusidxsUniq),1);
            clusMean = zeros(length(clusidxsUniq),2);
            for j = 1:length(clusidxsUniq)
                nExClus(j) = length(find(unLab(:,2) == clusidxsUniq(j)));
                clusMean(j,:) = mean(unPos(unLab(:,2) == clusidxsUniq(j),:),1);
            end
            d = sqrt(sum((clusMean - repmat([X Y],size(clusMean,1),1)).^2,2));
            [val,id] = sort(d,'ascend');
%             detidxs = find(unLab(:,1) == i-1 & unLab(:,2) == clusidxsUniq(id(1)));
            detidxs = find(unLab(:,1) == find(cidxs == i)-1 & unLab(:,2) == clusidxsUniq(id(1)));
            
%             mean between the two closest
%             d = inf(length(detidxs),length(detidxs));
%             for j = 1:length(detidxs)
%                 d(j,:) = sqrt(sum((repmat(unPos(detidxs(j),:),length(detidxs),1) - unPos(detidxs,:)).^2,2));
%             end
%             for j = 1:length(detidxs)
%                 d(j,j) = inf;
%             end
%             idx = find(d==min(min(d)));
%             [rx,cx] = ind2sub(size(d),idx);
%             det = mean(unPos(detidxs([rx(1) cx(1)]),:),1);
             
%             weighted sum excluding outliers
%             if (length(detidxs) > 2)
%                 d = inf(length(detidxs),length(detidxs));
%                 for j = 1:length(detidxs)
%                     d(j,:) = sqrt(sum((repmat(unPos(detidxs(j),:),length(detidxs),1) - unPos(detidxs,:)).^2,2));
%                 end
%                 dd = sum(d,2);
%                 [val,id2] = sort(dd,'descend');
%                 detidxs = detidxs(2:end);
%             end
%             w = unProb(detidxs,i);
%             w = w./sum(w);
%             det = sum(unPos(detidxs,:).*[w w],1);

%             medoid
%             m = mean(unPos(detidxs,:),1);
%             d = sqrt(sum((repmat(m,length(detidxs),1) - unPos(detidxs,:)).^2,2));
%             [val,id2] = min(d);
%             det = unPos(detidxs(id2),:);

            use_max = true;
            if use_max
                % maximum
                [val,idx] = max(unProb(detidxs,find(cidxs == i)));
                det = unPos(detidxs(idx),:);
                if locref
                    tmp = squeeze(locationRefine(:,i,:));
                    det = det + tmp(detidxs(idx),:);
                end
            else
                % weighted sum
                w = unProb(detidxs,find(cidxs == i));
                w = w./sum(w);
                locations = unPos(detidxs,:);
                if locref
                    tmp = squeeze(locationRefine(:,i,:));
                    locations = locations + tmp(detidxs,:);
                end
                det = sum(locations.*[w w], 1);
            end

            
            % DEBUG
%             [val,id] = max(unProb(detidxs,i));
%             det = unPos(detidxs(id),:);
%             figure(100); clf; imagesc(img); axis equal; hold on;
%             detidxsAll = unLab(:,2) == clusidxsUniq(id(1));
%             plot(unPos(detidxsAll,1),unPos(detidxsAll,2),'r+','Markersize',10);
%             plot(unPos(detidxs,1),unPos(detidxs,2),'b+','Markersize',10);
%             plot(det(:,1),det(:,2),'y+','Markersize',10);
        end
        
        % part is a joint
        detAll(jidx+1,:) = [det,-1];
        pts(i, :) = det;
    end
end
