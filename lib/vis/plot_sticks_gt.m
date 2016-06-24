function plot_sticks_gt(annolist, imgidxs, poseLL, visdir)

if (ischar(annolist))
    load('/home/andriluk/IMAGES/human_pose_dataset/dataset/dataset_release_candidate1/train/singlePerson/h200/annolist-singlePerson-h200');
    if (~exist(annolist,'var'))
        assert(exist('single_person_annolist','var'));
        annolist = single_person_annolist;
    end
end

if (nargin < 3)
    poseLL = [];
end

if (nargin < 4)
    visDir = '';
else
    assert(length(poseLL) == length(annolist));
end

colorset = {[236,112,20]/255; [78,179,211]/255; [0,104,55]/255; [129,15,124]/255; 'y'; 'k'; 'r'; 'c'; 'g'; 'b'};
skel = [0 1; 1 2; 3 4; 4 5; 6 7; 8 9; 10 11; 11 12; 13 14; 14 15];

% if (~exist(visdir, 'dir'))
%   mkdir(visdir);
% end

figure(102);
for imgidx = imgidxs;%1:length(annolist)
  clf;
  imagesc(imread(annolist(imgidx).image.name)); hold on;
  [~,fname] = fileparts(annolist(imgidx).image.name);
  axis equal;axis off;
  rect = annolist(imgidx).annorect;
  assert(length(rect) == 1);
  for ridx = 1:length(rect)
      points = rect(ridx).annopoints.point;
      for i = 1:size(skel,1)
          p1 = util_get_annopoint_by_id(points, skel(i,1));
          p2 = util_get_annopoint_by_id(points, skel(i,2));
          if (~isempty(p1) && ~isempty(p2))
              plot([p1.x; p2.x],[p1.y; p2.y],'color',colorset{i}, 'linewidth', 10);
          end
      end
      if (~isempty(poseLL))
          title(sprintf('pose LL: %1.2f',poseLL(imgidx)),'fontSize',16);
      end
  end
%   print(gcf, '-dpng', [visdir '/' fname '.png']);
  pause;
end
close(102);
