% function [path, filename, ext] = splitpathext(str)
function [path, filename, ext] = splitpathext(str)
  [path, filename] = splitpath(str);
  ptidx = strfind(filename, '.');
    
  if isempty(ptidx)
    ext = [];
  else
    ext = filename(ptidx(end)+1:end);
    filename = filename(1:ptidx(end)-1);
  end
end