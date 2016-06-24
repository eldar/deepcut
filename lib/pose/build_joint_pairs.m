function [ pwIdxsAllrel ] = build_joint_pairs( p )

pidxs = p.pidxs;

if p.person_part
    pidxs = [pidxs pidxs(end)+1];
end

pwIdxsAllrel = cell(1, 1);
n = 0;
for i = 1:length(pidxs)-1
    for j = i+1:length(pidxs)
        n = n + 1;
        pwIdxsAllrel{n} = [i j];
    end
end

