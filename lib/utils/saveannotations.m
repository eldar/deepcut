% annotations - annotation list
% outputfilename
% rescale_factor - rescale all annorects by this factor (default = 1)
% score_factor - multiply all scores by this factor (default = 1)
% abs_path - if false all image filenames will be saved as relative (default = true)
%
%function saveannotations(annotations, outputfilename, rescale_factor, score_factor, abs_path)
function saveannotations(annotations, outputfilename, rescale_factor, score_factor, abs_path, skip_empty)
  if nargin < 3
    rescale_factor = 1;
    score_factor = 1;
    abs_path = true;
  end

  if exist('skip_empty', 'var') == 0
    skip_empty = false;
  end

  if rescale_factor ~= 1
    assert(false, 'currently unsupported due introduction of rotated rectangles');
  end
  
  outputfilename = deblank(outputfilename);

  fprintf('saving annotations to %s\n', outputfilename);
  fid = fopen(outputfilename, 'w');

  if fid == -1 
    error('can not open output file');
  end

  if isfield(annotations, 'annorect')
    if rescale_factor ~= 1
      annotations = annotations_rescale(annotations, rescale_factor);
    end

    annotations = annotations_multscores(annotations, score_factor);
  end

  for ai = 1:length(annotations)
    [imgpath, filename] = splitpath(annotations(ai).image.name);
    if ~abs_path
      annotations(ai).image.name = filename;
    else
      if isempty(imgpath) && isfield(annotations(ai), 'image') && isfield(annotations(ai).image, 'path') && length(annotations(ai).image.path) > 0
        annotations(ai).image.name = [annotations(ai).image.path '/' annotations(ai).image.name];

        if isfield(annotations(ai).image, 'path')
          annotations(ai).image = rmfield(annotations(ai).image, 'path');
        end
      end
    end

  end

  nl_char = sprintf('\n');
  
  if strcmp(outputfilename(end-1:end), 'al')
    fprintf('using xml format\n');
    %fprintf(fid, '%s', annotations2xml(annotations,  skip_empty));

    fprintf(fid, '<annotationlist>%s', nl_char);

    for ai = 1:length(annotations)

      do_print = true;

      % MA: not tested 
      if (skip_empty)
	if ~(isfield(annotations(ai), 'annorect') && length(annotations(ai).annorect) > 0)
	  do_print = false;
	end
      end
      
      if do_print
        fprintf(fid, '%s', annotation2xml(annotations(ai)));
      end

    end

    fprintf(fid, '</annotationlist>%s', nl_char);

  else
    fprintf('using idl format (warning: fix issue with empty annorects) \n');
    %fprintf(fid, '%s', annotations2idl(annotations));

    for ai = 1:length(annotations)
      res = annotation2idl(annotations(ai));

      if ai == length(annotations)
	res = [res '.'];
      else
	res = [res ';'];
      end

      res = [res nl_char];

      fprintf(fid, '%s', res);

      fprintf('.');
      if mod(ai, 80) == 0
	fprintf('\n');
      end      
    end
    fprintf('\n');
  end

  assert(fid >= 0);
  fclose(fid);

end

function annotations = annotations_rescale(annotations, rescale_factor)
  for ai = 1:length(annotations)
    for ri = 1:length(annotations(ai).annorect)
      hx = (annotations(ai).annorect(ri).x1 + annotations(ai).annorect(ri).x2)/2;
      hy = (annotations(ai).annorect(ri).y1 + annotations(ai).annorect(ri).y2)/2;
      dx = abs(annotations(ai).annorect(ri).x2 - annotations(ai).annorect(ri).x1)/2;
      dy = abs(annotations(ai).annorect(ri).y2 - annotations(ai).annorect(ri).y1)/2;
      annotations(ai).annorect(ri).x1 = round(hx - rescale_factor*dx);
      annotations(ai).annorect(ri).y1 = round(hy - rescale_factor*dy);
      annotations(ai).annorect(ri).x2 = round(hx + rescale_factor*dx);
      annotations(ai).annorect(ri).y2 = round(hy + rescale_factor*dy);
    end
  end
end

function annotations = annotations_multscores(annotations, score_factor)
  for ai = 1:length(annotations)
    for ri = 1:length(annotations(ai).annorect)
      if ~isfield(annotations(ai).annorect(ri), 'score')
        annotations(ai).annorect(ri).score = -1;
      else
        annotations(ai).annorect(ri).score = score_factor * annotations(ai).annorect(ri).score;
      end
    end
  end
end

% function res = annotations2xml(annotations, skip_empty)
%   res = [];
%   nl_char = sprintf('\n');

%   for ai = 1:length(annotations)
%     include_anno = true;
    
%     if skip_empty && length(annotations(ai).annorect) == 0
%         include_anno = false;
%     end
    
%     if include_anno
%       res = [res '<annotation>' nl_char struct2xml(annotations(ai)) '</annotation>' nl_char];
%     end
%   end
%   res = ['<annotationlist>' nl_char res '</annotationlist>'];
% end

% function res = annotations2idl(annotations)
%   res = [];
%   nl_char = sprintf('\n');

%   for ai = 1:length(annotations)
%     res = [res '"' annotations(ai).image.name '"'];
    
    
%     if isfield(annotations(ai), 'annorect') && length(annotations(ai).annorect) > 0
%       res = [res ':'];
%       for ri = 1:length(annotations(ai).annorect)
%         str = sprintf('(%d, %d, %d, %d):%d', ...
%                       annotations(ai).annorect(ri).x1, ...
%                       annotations(ai).annorect(ri).y1, ...
%                       annotations(ai).annorect(ri).x2, ...
%                       annotations(ai).annorect(ri).y2, ...
%                       annotations(ai).annorect(ri).score);
                      
%         res = [res str];

%         if ri ~= length(annotations(ai).annorect)
%           res = [res ', '];
%         end
%       end

%       if ai == length(annotations)
%         res = [res '.'];
%       else
%         res = [res ';'];
%       end

%     else
%       res = [res ':(0, 0, 0, 0):-1;'];
%     end

%     res = [res nl_char];

%   end


% end


function res = annotation2xml(annotation)
  nl_char = sprintf('\n');
  res = ['<annotation>' nl_char ma_struct2xml(annotation) '</annotation>' nl_char];
end

function res = annotation2idl(annotation)
  res = [];
  nl_char = sprintf('\n');

  res = [res '"' annotation.image.name '"'];
  
  if isfield(annotation, 'annorect') && length(annotation.annorect) > 0
    res = [res ':'];
    for ri = 1:length(annotation.annorect)
      str = sprintf('(%d, %d, %d, %d):%d', ...
		    (annotation.annorect(ri).x1), ...
		    (annotation.annorect(ri).y1), ...
		    (annotation.annorect(ri).x2), ...
		    (annotation.annorect(ri).y2), ...
		    annotation.annorect(ri).score);

      if isfield(annotation.annorect(ri), 'silhouette')
	str = [str '/' num2str(annotation.annorect(ri).silhouette)];
      end
      
      res = [res str];

      if ri ~= length(annotation.annorect)
	res = [res ', '];
      end
    end
  else
    %res = [res ':(0, 0, 0, 0):-1;'];
    res = [res ';'];
  end

  %res = [res nl_char];
end
