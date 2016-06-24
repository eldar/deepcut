%function [path, filename] = splitpath(str)
function [path, filename] = splitpath(str)
  slashidx = strfind(str, '/');
    
  if isempty(slashidx)
    path = [];
    filename = str;
  else
    path = str(1:slashidx(end)-1);
    filename = str(slashidx(end)+1:end);
  end

end