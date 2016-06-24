function annolist = set_full_path(annolist,imgDir)

for imgidx = 1:length(annolist)
    if (isempty(fileparts(annolist(imgidx).image.name)))
        annolist(imgidx).image.name = [imgDir '/' annolist(imgidx).image.name];
    end
end

end