function write_text_matrix(fid, a, name)

fprintf(fid, '#\n');
fprintf(fid, '%s\n', name);
fprintf(fid, '%d %d\n', size(a, 1), size(a, 2));

num_rows = size(a, 1);
num_cols = size(a, 2);

for j = 1:num_rows
    for i = 1:num_cols
        if i == num_cols
            fprintf(fid, '%f\n', a(j, i));
        else
            fprintf(fid, '%f ', a(j, i));
        end
    end
end

end