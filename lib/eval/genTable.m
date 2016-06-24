function [row,header] = genTable(pck,name)

if length(pck)==16
    header = sprintf(' &Head & Shoulder & Elbow & Wrist & Hip & Knee  & Ankle & UBody & Total %s\n','\\');
    row = sprintf('%s& %1.1f  & %1.1f  & %1.1f  & %1.1f  & %1.1f  & %1.1f & %1.1f & %1.1f & %1.1f %s\n',name,(pck(13)+pck(14))/2,(pck(9)+pck(10))/2,(pck(8)+pck(11))/2,(pck(7)+pck(12))/2,(pck(3)+pck(4))/2,(pck(2)+pck(5))/2,(pck(1)+pck(6))/2,pck(end-1),pck(end),'\\');
else
    % 18 joints as in GVV project
    header = sprintf(' &Head & Shoulder & Elbow & Wrist & Hip & Knee  & Ankle & Total %s\n','\\');
    row = sprintf('%s& %1.1f  & %1.1f  & %1.1f  & %1.1f  & %1.1f  & %1.1f & %1.1f & %1.1f %s\n', name,...
       (pck(1)+pck(2))/2, (pck(3)+pck(7))/2, (pck(4)+pck(8))/2, (pck(6)+pck(5)+pck(10)+pck(9))/4,...
       (pck(11)+pck(15))/2, (pck(12)+pck(16))/2, (pck(13)+pck(14)+pck(17)+pck(18))/4, pck(end),'\\');
end

row = {row};

fprintf('\n%s %s',blanks(length(name)),header);
fprintf('%s\n',row{1});

end