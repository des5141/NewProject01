///hj_draw_comp(kor_font_sprite, ascii_font_sprite, x, y, str, colour, alpha)
/*
    (이전버전 벌식) 한글 문자열을 컴파일한 뒤 드로우 합니다.
    
    글자 크기는 그대로 글로벌 변수에서 가져옵니다.
    hj_init() 참고!
    
    컴파일 된 데이터는 global.hjCache 해시맵 변수에 캐쉬됩니다.
    문자열을 컴파일하지 않고 스트링에서 바로 드로잉할려면 hj_draw_comp_raw() 를 사용해주세요!
    
    ==================================
    kor_font_sprite & ascii_font_sprite : 폰트 스프라이트
    (ascii_font_sprite 에 -1를 넣으면 kor_font_sprite으로 ASCII 문자까지 커버합니다.)
    (이전 버전의 global.hjUseAsciiSprite 와 같은 효과)
    
    x, y : 글자 그리는 좌표
    str : 그릴 문자열
    colour : 글자 색
    alpha : 글자 알파 (투명도)
*/

// 변수
var _korspr = argument0;
var _asciispr = argument0;
var _str = argument4, _linestr;
var _strx = argument2, _stry = argument3; // 글자 위치
var _offx = _strx, _offy = _stry; // 글자 위치에 더해지는 오프셋 변수 (줄바꿈 & 정렬... ETC에 사용)

var _strcol = argument5, _stralpha = argument6;
var _strlen = string_length(_str);
var _asciioff = global.hjCompOffAscii;
var _asciiwid = global.hjCharWidHan;
var _asciihei = global.hjCharHeiHan;

// 글자 렌더링 준비
if (argument1 != -1)
{
    _asciioff = 0;
    _asciispr = argument1;
    
    _asciiwid = global.hjCharWidAscii;
    _asciihei = global.hjCharHeiAscii;
}

// string_char_at 이 드럽게 느려서 배열로 바꿔줍니다.
// https://forum.yoyogames.com/index.php?threads/draw_wrapped_colored_text-optimization-the-mother-of-all-textboxes.35901/
var _strarray = global.hjCacheData[? _str + "_c"];
if (_strarray == undefined)
{
    for (var i=0; i<_strlen; i++)
    {
        var _byte = string_char_at(_str, i + 1);
        _strarray[i] = _byte;
    }
    
    global.hjCacheData[? _str + "_c"] = _strarray;
}
_strlen = array_length_1d(_strarray);

_linestr = hj_string_get_first_line(_str); // 첫 줄 가져오기
_str = string_delete(_str, 1, string_length(_linestr)); // 첫 줄을 제외한 글자 가져오기

// 줄 높이 구하기 : ASCII 폰트 높이와 한글 폰트 높이 중 더 큰 것
var _linehei = max(global.hjCharHeiAscii, global.hjCharHeiHan) + global.hjGlyphLineheight;
var _strwid = hj_string_width_line(_linestr), _strhei = hj_string_height(argument2);

// 수평 정렬
_offx -= (_strwid >> 1) * global.hjDrawAlignH;
    
// 수직 정렬
_offy -= (_strhei >> 1) * global.hjDrawAlignV;


// 글자 렌더링 루틴
var _curchr = "", _curord = $BEEF, _widdata;
var _prevchr = false; // 바로 전 글자
var _kr;
var _idx, _u, _v;
var _first, _mid, _last, _rowlast, _rowmid;
for (var i=0; i<_strlen; i++)
{
    // 현재 위치의 글자 가져오기 & 오프셋 계산
    _curchr = _strarray[@ i];//string_char_at(_str, i);
    _curord = ord(_curchr);
    
    // ASCII (& 줄바꿈 etc)
    if (_curord <= global.hjComp_ASCII_LIMIT)
    {
        // 줄바꿈
        if (_curchr == "#" && _prevchr != "\")
        {
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
            _offy += _linehei;
            
            // 수평 정렬
            _offx -= (_strwid >> 1) * global.hjDrawAlignH;
            continue; // 쌩까기
        }
        
        /*
        _idx = _curord;
        _u = (_idx % _asciicol) * _asciiwid;
        _v = (_idx div _asciicol) * _asciihei + _asciioff;
        draw_sprite_general(_asciispr, 0, _u, _v, _asciiwid, _asciihei, _offx, _offy, 1, 1, 0, _strcol, _strcol, _strcol, _strcol, 1);
        */
        _idx = _curord + _asciioff;
        draw_sprite_ext(_asciispr, _idx, _offx, _offy, 1, 1, 0, _strcol, _stralpha);
        
        // 오프셋 증가
        _offx += _asciiwid + global.hjGlyphKerning;
    }
    else if (_curord >= $AC00 && _curord <= $D7AF) // 조합
    {
        _kr = _curord - $AC00;
        
        // 초/중/종성 구하기 & 벌 (오프셋) 구하기
        _first = (_kr div 588);
        _mid = ((_kr % 588) div 28);
        _last = (_kr % 28);
        _rowlast = global.hjComp_LUT_BEOL_MID[@ _mid] * global.hjCompSpecialMiddle;
        _rowmid = global.hjComp_LUT_BEOL_LAST[@ _last] * global.hjCompSpecialLast;
        
        draw_sprite_ext(_korspr, _first + global.hjCompOffFirst + _rowlast + _rowmid * 2, _offx, _offy, 1, 1, 0, _strcol, _stralpha);
        draw_sprite_ext(_korspr, _mid + global.hjCompOffMiddle + _rowmid, _offx, _offy, 1, 1, 0, _strcol, _stralpha);
        draw_sprite_ext(_korspr, _last + global.hjCompOffLast + _rowlast, _offx, _offy, 1, 1, 0, _strcol, _stralpha);
        // draw_sprite_general(_korspr, 0, _u, _v, global.hjCharWidHan, global.hjCharHeiHan, _offx, _offy, 1, 1, 0, _strcol, _strcol, _strcol, _strcol, 1);
        /*
        _u = _first * global.hjCharWidHan;
        _v = global.hjCompOffFirst + _rowlast + _rowmid * 2;
        draw_sprite_general(_korspr, 0, _u, _v, global.hjCharWidHan, global.hjCharHeiHan, _offx, _offy, 1, 1, 0, _strcol, _strcol, _strcol, _strcol, 1);
        
        _u = _mid * global.hjCharWidHan;
        _v = global.hjCompOffMiddle + _rowmid;
        draw_sprite_general(_korspr, 0, _u, _v, global.hjCharWidHan, global.hjCharHeiHan, _offx, _offy, 1, 1, 0, _strcol, _strcol, _strcol, _strcol, 1);
        
        _u = _last * global.hjCharWidHan;
        _v = global.hjCompOffLast + _rowlast;
        draw_sprite_general(_korspr, 0, _u, _v, global.hjCharWidHan, global.hjCharHeiHan, _offx, _offy, 1, 1, 0, _strcol, _strcol, _strcol, _strcol, 1);
        */
        
        // 오프셋 증가
        _offx += global.hjCharWidHan + global.hjGlyphKerning;
    }
    else if (_curord >= $3130 && _curord <= $3163)// 호환용 자모 ([ㄱㄴㄷㄻㅄ ㅏㅒㅑㅛ] ETC...)
    {
        _kr = _curord - $3130;
        
        /*
        _u = (_kr % 28) * global.hjCharWidHan;
        _v = (_kr div 28) * global.hjCharHeiHan + global.hjCompOffJamo;
        draw_sprite_general(_korspr, 0, _u, _v, global.hjCharWidHan, global.hjCharHeiHan, _offx, _offy, 1, 1, 0, _strcol, _strcol, _strcol, _strcol, 1);
        */
        draw_sprite_ext(_korspr, _kr + global.hjCompOffJamo, _offx, _offy, 1, 1, 0, _strcol, _stralpha);
        
        // 오프셋 증가
        _offx += global.hjCharWidHan + global.hjGlyphKerning;
    }
    else // 며느리도 모르는 외계어
    {
        _kr = "u["+string(_curord)+"]";
        // draw_sprite_ext(_asciispr, _asciioff + 63, _dx, _dy, 1, 1, 0, c_red, 1); // ????????
        draw_text_colour(_offx, _offy, _kr, c_red, c_red, c_red, c_red, 1);
        
        // 오프셋 증가
        _offx += string_width(_kr) + global.hjGlyphKerning;
    }
    
    // 이전 글자
    _prevchr = _curchr;
}
