function styles = get_vis_styles()

    colors = {'r','g','b','c','m','y'};
    markers = {'+','o','s', 'x','.'}; %,'-','s','d'};
    styles = {};
    j = 1;
    for m = 1:length(markers)
        for c = 1:length(colors)
            styles{j} = [colors{c} markers{m}];
            j = j + 1;
        end
    end