function [ joints ] = augment_joints( p, joints )

if p.person_part
    joints_f = joints(~isnan(joints(:,1)), :);
    mass_centre = mean(joints_f, 1);
    joints = [joints; mass_centre];
end

end

