function angles = wrapMinusPiPifast(angles)

tol = 0.001;

angles(angles < -pi) = angles(angles < -pi) + 2*pi;
angles(angles < -pi) = angles(angles < -pi) + 2*pi;

angles(angles > pi) = angles(angles > pi) - 2*pi;
angles(angles > pi) = angles(angles > pi) - 2*pi;

angles(angles == pi) = angles(angles == pi) - tol;
angles(angles == -pi) = angles(angles == -pi) + tol;

assert(~any(angles > pi));
assert(~any(angles < -pi));

end