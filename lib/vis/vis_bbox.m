function vis_bbox(bbox,color)

if (nargin < 2)
    color = 'g';
end
for i=1:size(bbox,1)
    rectangle('Position', [bbox(i,1) bbox(i,2) bbox(i,3)-bbox(i,1) bbox(i,4)-bbox(i,2)],'LineWidth',3,'EdgeColor',color);
end
set(gca,'YDir','reverse');

end