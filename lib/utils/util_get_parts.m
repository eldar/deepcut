function [joints, parts, keypoints] = util_get_parts()

parts = [];
joints = [];

parts.id    = 0; parts.pos    = [0 1]; parts.xaxis    = [1 0];
parts(2).id = 1; parts(2).pos = [1 2]; parts(2).xaxis = [2 1];
parts(3).id = 2; parts(3).pos = [3 4]; parts(3).xaxis = [3 4];
parts(4).id = 3; parts(4).pos = [4 5]; parts(4).xaxis = [4 5];
parts(5).id = 4; parts(5).pos = [6 7]; parts(5).xaxis = [7 6];
parts(6).id = 5; parts(6).pos = [8 9]; parts(6).xaxis = [9 8];
parts(7).id = 6; parts(7).pos = [11 10]; parts(7).xaxis = [11 10];
parts(8).id = 7; parts(8).pos = [11 12]; parts(8).xaxis = [12 11];
parts(9).id = 8; parts(9).pos = [13 14]; parts(9).xaxis = [13 14];
parts(10).id = 9; parts(10).pos = [14 15]; parts(10).xaxis = [14 15];

joints.id    = 0; joints.child    = parts(1); joints.parent    = parts(2); joints.pos    = 1;
joints(2).id = 1; joints(2).child = parts(2); joints(2).parent = parts(5); joints(2).pos = 2;
joints(3).id = 2; joints(3).child = parts(3); joints(3).parent = parts(5); joints(3).pos = 3;
joints(4).id = 3; joints(4).child = parts(4); joints(4).parent = parts(3); joints(4).pos = 4;
joints(5).id = 4; joints(5).child = parts(6); joints(5).parent = parts(5); joints(5).pos = 7;
joints(6).id = 5; joints(6).child = parts(7); joints(6).parent = parts(8); joints(6).pos = 11;
joints(7).id = 6; joints(7).child = parts(8); joints(7).parent = parts(5); joints(7).pos = 12;
joints(8).id = 7; joints(8).child = parts(9); joints(8).parent = parts(5); joints(8).pos = 13;
joints(9).id = 8; joints(9).child = parts(10); joints(9).parent = parts(9);joints(9).pos = 14;

keypoints.id    = 0; keypoints.pos    = 0;
keypoints(2).id = 1; keypoints(2).pos = 1;
keypoints(3).id = 2; keypoints(3).pos = 2;
keypoints(4).id = 3; keypoints(4).pos = 3;
keypoints(5).id = 4; keypoints(5).pos = 4;
keypoints(6).id = 5; keypoints(6).pos = 5;
keypoints(7).id = 6; keypoints(7).pos = 8;
keypoints(8).id = 7; keypoints(8).pos = 9;
keypoints(9).id = 8; keypoints(9).pos = 10;
keypoints(10).id = 9; keypoints(10).pos = 11;
keypoints(11).id = 10; keypoints(11).pos = 12;
keypoints(12).id = 11; keypoints(12).pos = 13;
keypoints(13).id = 12; keypoints(13).pos = 14;
keypoints(14).id = 13; keypoints(14).pos = 15;

end