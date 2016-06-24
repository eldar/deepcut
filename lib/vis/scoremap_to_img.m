function res = scoremap_to_img(sc, color)
    %res = zeros(size(sc, 1), size(sc, 2), 3);
    c = reshape(color, 1, 1, 3);
    res = repmat(c, size(sc, 1), size(sc, 2), 1);
    res = bsxfun(@times, res, sc);
end
