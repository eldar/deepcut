function [  ] = rpn_detect(  )

    if p.rpn_detect
        objpos = annolist(i).annorect.objpos;
        objpos = single([objpos.x objpos.y]);
        
        pos = int32((objpos*scale_factor - half_stride)/stride) + 1;
        row = pos(2);
        col = pos(1);
        
        anchors = squeeze(rpn_prob(row, col, :));
        [~,anch] = max(anchors);
        
        t = squeeze(rpn_bbox(row, col, anch, :));
        
        anchor_types = single([ 1, 130; 1, 211; 2, 153; 3, 125; 4, 97]);
        w_a = anchor_types(anch, 2);
        h_a = w_a * anchor_types(anch, 1);
        x_a = objpos(1);
        y_a = objpos(2);
        
        x = x_a + w_a*t(1);
        y = y_a + h_a*t(2);
        w = w_a * exp(t(3));
        h = h_a * exp(t(4));

        extra_margin = 0;
        w = w + extra_margin;
        h = h + extra_margin;

        x_r = x - w/2;
        y_r = y - h/2;
        
        rect_orig = single([x_r y_r x_r+w y_r+h]);
        rect = int32((rect_orig*scale_factor - half_stride)/stride) + 1;
        sm_height = size(rpn_prob, 1);
        sm_width = size(rpn_prob, 2);
        rect(1) = max(rect(1), 1);
        rect(2) = max(rect(2), 1);
        rect(3) = min(rect(3), sm_width);
        rect(4) = min(rect(4), sm_height);
        
        if bVis
            scmap = visualise_scoremap( rpn_prob );
            figure(3);
            imshow(scmap);

            figure(4);
            imagesc(im_orig);
            rectangle('Position', [x_r y_r w h]);
        end
    end

end

