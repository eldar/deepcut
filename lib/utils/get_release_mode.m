function res = get_release_mode()

global POSE_RELEASE_MODE;

if isempty(POSE_RELEASE_MODE)
    POSE_RELEASE_MODE = false;
end

res = POSE_RELEASE_MODE;

end

