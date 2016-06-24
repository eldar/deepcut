function [joints, parts] = util_get_parts24()

parts = [];
joints = [];

parts.id    = 0;   parts.pos    = [0 0];     parts.xaxis    = [1 0];
parts(2).id = 1;   parts(2).pos = [0 1];     parts(2).xaxis = [1 0];
parts(3).id = 2;   parts(3).pos = [1 1];     parts(3).xaxis = [1 0];
parts(4).id = 3;   parts(4).pos = [1 2];     parts(4).xaxis = [2 1];
parts(5).id = 4;   parts(5).pos = [2 2];     parts(5).xaxis = [2 1];
parts(6).id = 5;   parts(6).pos = [3 3];     parts(6).xaxis = [3 4];
parts(7).id = 6;   parts(7).pos = [3 4];     parts(7).xaxis = [3 4];
parts(8).id = 7;   parts(8).pos = [4 4];     parts(8).xaxis = [4 5];
parts(9).id = 8;   parts(9).pos = [4 5];     parts(9).xaxis = [4 5];
parts(10).id = 9;  parts(10).pos = [5 5];    parts(10).xaxis = [4 5];
parts(11).id = 10; parts(11).pos = [6 7];    parts(11).xaxis = [7 6];
parts(12).id = 11; parts(12).pos = [8 9];    parts(12).xaxis = [9 8];
parts(13).id = 12; parts(13).pos = [10 10];  parts(13).xaxis = [11 10];
parts(14).id = 13; parts(14).pos = [11 10];  parts(14).xaxis = [11 10];
parts(15).id = 14; parts(15).pos = [11 11];  parts(15).xaxis = [11 10];
parts(16).id = 15; parts(16).pos = [12 11];  parts(16).xaxis = [12 11];
parts(17).id = 16; parts(17).pos = [12 12];  parts(17).xaxis = [12 11];
parts(18).id = 17; parts(18).pos = [13 13];  parts(18).xaxis = [13 14];
parts(19).id = 18; parts(19).pos = [13 14];  parts(19).xaxis = [13 14];
parts(20).id = 19; parts(20).pos = [14 14];  parts(20).xaxis = [14 15];
parts(21).id = 20; parts(21).pos = [14 15];  parts(21).xaxis = [14 15];
parts(22).id = 21; parts(22).pos = [15 15];  parts(22).xaxis = [14 15];
parts(23).id = 22; parts(23).pos = [8 8];  parts(23).xaxis = [9 8];
parts(24).id = 23; parts(24).pos = [9 9];  parts(24).xaxis = [9 8];

joints.id    = 0;   joints.child    = parts(1);   joints.parent    = parts(2);   joints.pos    = 0;
joints(2).id = 1;   joints(2).child = parts(2);   joints(2).parent = parts(3);   joints(2).pos = 1;
joints(3).id = 2;   joints(3).child = parts(3);   joints(3).parent = parts(4);  joints(3).pos = 1;
joints(4).id = 3;   joints(4).child = parts(4);   joints(4).parent = parts(5);   joints(4).pos = 2;
joints(5).id = 4;   joints(5).child = parts(5);   joints(5).parent = parts(11);  joints(5).pos = 2;

joints(6).id = 5;   joints(6).child = parts(6);   joints(6).parent = parts(11);  joints(6).pos = 3;
joints(7).id = 6;   joints(7).child = parts(7);   joints(7).parent = parts(6);   joints(7).pos = 3;
joints(8).id = 7;   joints(8).child = parts(8);   joints(8).parent = parts(7);   joints(8).pos = 4;
joints(9).id = 8;   joints(9).child = parts(9);   joints(9).parent = parts(8);  joints(9).pos = 4;
joints(10).id = 9;  joints(10).child = parts(10);  joints(10).parent = parts(9);  joints(10).pos = 4;

joints(11).id = 10; joints(11).child = parts(12); joints(11).parent = parts(11);  joints(11).pos = 7;

joints(12).id = 11; joints(12).child = parts(13); joints(12).parent = parts(14);  joints(12).pos = 10;
joints(13).id = 12; joints(13).child = parts(14); joints(13).parent = parts(15); joints(13).pos = 11;
joints(14).id = 13; joints(14).child = parts(15); joints(14).parent = parts(16); joints(14).pos = 11;
joints(15).id = 14; joints(15).child = parts(16); joints(15).parent = parts(17); joints(15).pos = 12;
joints(16).id = 15; joints(16).child = parts(17); joints(16).parent = parts(11); joints(16).pos = 12;

joints(17).id = 16; joints(17).child = parts(18); joints(17).parent = parts(11);  joints(17).pos = 13;
joints(18).id = 17; joints(18).child = parts(19); joints(18).parent = parts(18); joints(18).pos = 13;
joints(19).id = 18; joints(19).child = parts(20); joints(19).parent = parts(19); joints(19).pos = 14;
joints(20).id = 19; joints(20).child = parts(21); joints(20).parent = parts(20); joints(20).pos = 14;
joints(21).id = 20; joints(21).child = parts(22); joints(21).parent = parts(21); joints(21).pos = 15;
joints(22).id = 21; joints(22).child = parts(24); joints(22).parent = parts(23); joints(22).pos = 8;


end