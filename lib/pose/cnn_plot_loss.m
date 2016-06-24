function cnn_plot_loss(fn)

fid = fopen(fn);

num_max = 10000000;
iters = zeros(num_max, 1);
loss = zeros(num_max, 1);

count = 0;

tline = fgetl(fid); % header
tline = fgetl(fid);
while ischar(tline)
    %disp(tline)
    [stuff, ~] = sscanf(tline, '%d %f %f %f');
    count = count + 1;
    iters(count) = stuff(1);
    loss(count) = stuff(3);
    tline = fgetl(fid);
end

iters = iters(1:count);
loss = loss(1:count);

filt_size = 100;
filt = ones(filt_size, 1)/filt_size;
loss = conv(loss, filt, 'same');

plot(iters, loss);



fclose(fid);
end

