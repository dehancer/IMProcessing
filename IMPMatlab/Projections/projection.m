 xy0.x = 0; xy0.y = 0;
 xy1.x = 0; xy1.y = 1;
 xy2.x = 1; xy2.y = 0;
 xy3.x = 1; xy3.y = 1;

 uv0.x = -0.1; uv0.y = 0;
 uv1.x = 0; uv1.y = 1;
 uv2.x = 1; uv2.y = 0;
 uv3.x = 1; uv3.y = 1.1;

 
 A = [
    xy0.x, xy0.y, 1, 0,     0,     0, -uv0.x * xy0.x, -uv0.x * xy0.y;
    0,     0,     0, xy0.x, xy0.y, 1, -uv0.y * xy0.x, -uv0.y * xy0.y;
    xy1.x, xy1.y, 1, 0,     0,     0, -uv1.x * xy1.x, -uv1.x * xy1.y;
    0,     0,     0, xy1.x, xy1.y, 1, -uv1.y * xy1.x, -uv1.y * xy1.y;
    xy2.x, xy2.y, 1, 0,     0,     0, -uv2.x * xy2.x, -uv2.x * xy2.y;
    0,     0,     0, xy2.x, xy2.y, 1, -uv2.y * xy2.x, -uv2.y * xy2.y;
    xy3.x, xy3.y, 1, 0,     0,     0, -uv3.x * xy3.x, -uv3.x * xy3.y;
    0,     0,     0, xy3.x, xy3.y, 1, -uv3.y * xy3.x, -uv3.y * xy3.y;
];

B = [
    uv0.x;
    uv0.y;
    uv1.x;
    uv1.y;
    uv2.x;
    uv2.y;
    uv3.x;
    uv3.y
];

h = mldivide(A,B);
H = [ 
    h(1) h(2) h(3);
    h(4) h(5) h(6);
    h(7) h(8) 1;
    ]

