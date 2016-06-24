function demo_multiperson()

experiment_index = 1;
image_index = 2;

set_release_mode(true);

% process input image with the CNN and cache confidence maps to the disk
cnn_cache_features( experiment_index, 'test', image_index, 1);

% prepare and run ILP inference
test_spatial_app_neighbour(experiment_index, image_index, 1, true, true);

% visualise predictions
vis_people(experiment_index, image_index);

end

