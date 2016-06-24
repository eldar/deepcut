function res = struct2xml(s)
  res = [];
  names = fieldnames(s);
  nl_char = sprintf('\n');

  for i = 1:length(names)
    % skip empty fields
    if isempty(s.(names{i}))
      continue;
    end

    if isnumeric(s.(names{i}))
      if length(s.(names{i})) > 1
        %warning(['ignoring field ' names{i} ': arrays are not supported']);
      else
        res = [res tagged_string( num2str(s.(names{i})), names{i}) nl_char];
      end
    elseif ischar(s.(names{i}))
      res = [res tagged_string(s.(names{i}), names{i}) nl_char];
    elseif isstruct(s.(names{i}))
      for j = 1:length(s.(names{i}))
        res = [res tagged_string(struct2xml(s.(names{i})(j)), names{i}), nl_char];
      end
    else
      error('unsupported field type')
    end
  end  

end

function res = tagged_string(str, tag)
  res = ['<' tag '>' str '</' tag '>'];
end