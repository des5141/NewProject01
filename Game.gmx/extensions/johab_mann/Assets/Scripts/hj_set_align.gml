/// hj_set_align(halign, valign)
/*
    한글을 드로우할때 쓸 정렬 방식을 정합니다.
    ==============================
    halign : 수직 정렬 [0 = 왼쪽, 1 = 가운데, 2 = 오른쪽] 기준
    valign : 수평 정렬 [0 = 위쪽, 1 = 가운데, 2 = 아래쪽] 기준
    ... 그냥 draw_set_halign(), draw_set_valign() 과 비슷해요.
*/
global.hjDrawAlignH = argument0; // 정렬
global.hjDrawAlignV = argument1;
