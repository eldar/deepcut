function torsoSize = util_get_torso_size(rect)

prh = util_get_annopoint_by_id(rect.annopoints.point,2); % right hip
pls = util_get_annopoint_by_id(rect.annopoints.point,13); % left shoulder
plh = util_get_annopoint_by_id(rect.annopoints.point,3); % left hip
prs = util_get_annopoint_by_id(rect.annopoints.point,12); % right shoulder
if (isempty(prh) || isempty(pls) || isempty(plh) || isempty(prs))
    torsoSize = nan;
else
    % torso diagonal
%     torsoSize = 0.5*(norm([prh.x prh.y]-[pls.x pls.y]) + norm([plh.x plh.y]-[prs.x prs.y]));
    torsoSize = norm([pls.x pls.y]-[prh.x prh.y]); % assymetric measure lsh - rhip
end
end