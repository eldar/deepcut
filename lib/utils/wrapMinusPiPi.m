function angles = wrapMinusPiPi(angles)

tol = 0.001;

for i=1:length(angles)
    
    while (angles(i) < -pi)
        angles(i) = angles(i) + 2*pi;
    end
    
    while (angles(i) > pi)
        angles(i) = angles(i) - 2*pi;
    end
    
    if (angles(i) == pi)
        angles(i) = angles(i) - tol;
    end
    
    if (angles(i) == -pi)
        angles(i) = angles(i) + tol;
    end

    assert(angle(i) > -pi);
    assert(angle(i) < pi);
    
end


end