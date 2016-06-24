% a=0.005, x^2
% a=0.0002, abs(x)^3
% a=0.0001, x^4

a = 0.005;
b = 0.00025;
xs = 0:50;
ys2 = zeros(length(xs), 1);
ys3 = zeros(length(xs), 1);
for i = 1:length(xs)
    ys2(i) = exp(-a*abs(xs(i))^2);
    ys3(i) = exp(-b*abs(xs(i))^3);
end
plot(xs, ys2);
hold on;
plot(xs, ys3);
hold off;