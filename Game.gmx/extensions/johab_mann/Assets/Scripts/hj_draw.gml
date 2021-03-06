///hj_draw(x, y, str, colour, alpha)
/*
    (도깨비한글 8x4x4벌식) 한글 문자열을 컴파일한 뒤 드로우 합니다.
    컴파일 된 데이터는 global.hjCache 해시맵 변수에 캐쉬됩니다.
    
    문자열을 컴파일하지 않고 스트링에서 바로 드로잉할려면 hj_draw_raw() 를 사용해주세요!
    
    ==================================
    x, y : 글자 그리는 좌표
    str : 그릴 문자열
    colour : 글자 색
    alpha : 글자 알파 (투명도)
*/
// 변수
var _str = argument2;
var _linestr; // 현재 줄 스트링
var _strx = argument0, _stry = argument1; // 글자 위치
var _offx = _strx, _offy = _stry; // 최종 글자 위치 변수 (줄바꿈 & 정렬... ETC에 사용)
var _strcol = argument3, _stralpha = argument4;
var _strlen;

// 글자 렌더링 준비
// string_char_at() 이 드럽게 느려서 배열로 바꿔줍니다. 배열로 바꿔주는 김에 초/중/종성 인덱스도 같이 캐시해줍니다.
// https://forum.yoyogames.com/index.php?threads/draw_wrapped_colored_text-optimization-the-mother-of-all-textboxes.35901/
var _strarray = global.hjCacheData[? _str];
if (_strarray == undefined)
{
    _strarray = hj_dkb_compile_str(_str);
    global.hjCacheData[? _str] = _strarray;
}
_strlen = array_length_1d(_strarray);

_linestr = hj_string_get_first_line(_str); // 첫 줄 가져오기
_str = string_delete(_str, 1, string_length(_linestr)); // 첫 줄을 제외한 글자 가져오기

// 글자 너비 & 높이
// _strhei 는 argument2(원본 문자열) 에서 계산합니다.
// 보시다시피 위에서 _str를 수정해버렸으니깐요
var _strwid = hj_string_width_line(_linestr), _strhei = hj_string_height(argument2);

// 수평 정렬
/*
if (global.hjDrawAlignH == 1) // 가운데 정렬
    _offx -= (_strwid * 0.5);
else if (global.hjDrawAlignH == 2) // 오른쪽 정렬
    _offx -= _strwid;
*/

// 위 코드를 요래 간략화했심다.
_offx -= (_strwid >> 1) * global.hjDrawAlignH;
    
// 수직 정렬
_offy -= (_strhei >> 1) * global.hjDrawAlignV;

// 글자 렌더링 루틴
// 미리 처리된 글자를 _strarray 배열에서 하나씩 빼먹으며 그 데이타로 글자를 드로우합니다.
var _data = -1, _widdata = -1;
var _type, _idx1, _idx2, _idx3;
var _hanw = global.hjCharWidHan + global.hjGlyphKerning;
var _asciiw = global.hjCharWidAscii + global.hjGlyphKerning;
for (var i=0; i<_strlen; i++)
{
    // 현재 위치의 글자 가져오기 & 오프셋 계산
    _data = _strarray[@ i];
    _type = _data[@ 0];
    _idx1 = _data[@ 2];
    _idx2 = _data[@ 3];
    _idx3 = _data[@ 4];

    switch (_type)
    {
        case 0: // 다음 줄
            _linestr = hj_string_get_first_line(_str);
            _str = string_delete(_str, 1, string_length(_linestr));
            
            // 다음 줄 넓이 구하기
            // _strwid = hj_string_width_line(_linestr);
            // 캐시 안되어있으면 계산 & 캐시
            _widdata = global.hjCacheWid[? _linestr];
            if (_widdata == undefined)
            {
                _widdata = hj_string_width_line_adv(_linestr);
                global.hjCacheWid[? _linestr] = _widdata;
            }
            
            // 뤼얼 바보같은 생각 : 최종 계산 결과를 또 다시 캐시하면??
            // 결과 : 50+ FPS 증가 (??????????????????????)
            _strwid = global.hjCacheMisc[? _linestr];
            if (_strwid == undefined)
            {
                _strwid = _widdata[@ 0] * (global.hjCharWidAscii + global.hjGlyphKerning)
                        + _widdata[@ 1] * (global.hjCharWidHan + global.hjGlyphKerning);
                global.hjCacheMisc[? _linestr] = _strwid;
            }
            
            // 오프셋 값 변경
            _offx = _strx;
            _offy += global.hjGlyphLineheight + global.hjCharHeiAscii;
            
            // 수평 정렬
            _offx -= (_strwid >> 1) * global.hjDrawAlignH;
            break;
        case 1: // 스페이스바 / 화이트스페이스
            // 오프셋 증가
            _offx += _asciiw;
            break;
        default:
        case 2: // ASCII
            draw_sprite_ext(global.hjSpriteAscii, _idx1, _offx, _offy, 1, 1, 0, _strcol, _stralpha);
            
            // 오프셋 증가
            _offx += _asciiw;//global.hjCharWidAscii + global.hjGlyphKerning;
            break;
        case 3: // 조합형 한글
            draw_sprite_ext(global.hjSpriteHan, _idx1, _offx, _offy, 1, 1, 0, _strcol, _stralpha);
            draw_sprite_ext(global.hjSpriteHan, _idx2, _offx, _offy, 1, 1, 0, _strcol, _stralpha);
            draw_sprite_ext(global.hjSpriteHan, _idx3, _offx, _offy, 1, 1, 0, _strcol, _stralpha);
            
            // 오프셋 증가
            _offx += _hanw;//global.hjCharWidHan + global.hjGlyphKerning;
            break;
            
        case 4: // 한글 자모
            draw_sprite_ext(global.hjSpriteHan, _idx1, _offx, _offy, 1, 1, 0, _strcol, _stralpha);
            
            // 오프셋 증가
            _offx += _hanw;//global.hjCharWidHan + global.hjGlyphKerning;
            break;
    }
}
