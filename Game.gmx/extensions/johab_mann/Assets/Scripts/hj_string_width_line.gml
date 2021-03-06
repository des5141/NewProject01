///hj_string_width_line(str)
/*
    주어진 한글 문자열 첫 줄(만)의 너비를 반환합니다.
    계산된 너비는 변수에 캐시됩니다... 이를 원하지 않으시면
    hj_string_width_line_raw()를 사용해주시고, 결과값을 이용해 계산해주세요!!
    (hj_string_width_line_raw()는 ASCII 글자 개수(0번째) & 한글 문자 개수(1번째) 정보가 들어있는 배열을 반환합니다.)
*/

var _linestr = hj_string_get_first_line(argument0);
var _data = global.hjCacheWid[? _linestr];

// 캐시 안되어있으면 계산 & 캐시
if (_data == undefined)
{
    _data = hj_string_width_line_adv(_linestr);
    global.hjCacheWid[? _linestr] = _data;
}


// 계산 & 반환
return _data[@ 0] * (global.hjCharWidAscii + global.hjGlyphKerning) + _data[@ 1] * (global.hjCharWidHan + global.hjGlyphKerning);
