function [row,header] = genTablePCP(pcp,name)

assert(length(pcp)==11)
header = cell(2,1);
header{1} = sprintf(' Torso & Upper & Lower & Upper & Fore- & Head  & Upper & Total %s\n','\\');
header{2} = sprintf('       & Leg   & Leg&  & Arm   & arm   &       & body  &       %s\n','\\');
row = sprintf('%s &%1.1f  & %1.1f  & %1.1f  & %1.1f  & %1.1f  & %1.1f & %1.1f & %1.1f %s\n',name,pcp(5),(pcp(2)+pcp(3))/2,(pcp(1)+pcp(4))/2,(pcp(8)+pcp(9))/2,(pcp(7)+pcp(10))/2,pcp(6),(pcp(5)+pcp(8)+pcp(9)+pcp(7)+pcp(10))/5,pcp(11),'\\');
row = {row};

fprintf('\n%s %s',blanks(length(name)),header{1});
fprintf('\n%s %s',blanks(length(name)),header{2});
fprintf('%s\n',row{1});
end