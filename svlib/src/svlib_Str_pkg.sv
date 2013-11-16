`ifndef SVLIB_STR_PKG__DEFINED
`define SVLIB_STR_PKG__DEFINED

`include "svlib_macros.sv"

package svlib_Str_pkg;

  typedef string qs[$];
  
  function automatic bit isspace(byte unsigned ch);
    return (ch inside {"\t", "\n", "\r", " ", 160});  // nbsp
  endfunction
  
  virtual class svlib_base;
  endclass
  
  // Str: various string manipulations.
  // Most functions come in two flavors:
  // - a package version named str_XXX that takes a string value,
  //   does some work on it and returns a result; and
  // - an object version named .XXX that operates on a stored
  //   Str object, possibly returning a result and possibly
  //   modifying the stored object.
  //
  class Str extends svlib_base;
  
    typedef enum {NONE, LEFT, RIGHT, BOTH} side_e;
  
    // Save a string as an object so that further manipulations can
    // be performed on it.  Get and set the object's string value.
    extern static function Str create(string s = "");
    extern function string get();
    extern function void   set(string s);
    extern function int    len();
    
    // Find the first occurrence of substr in s, starting from the "start"
    // position. If a match is found, return the index of the first character
    // of the match.  If no match is found, return -1.
    extern function int    locate(string substr, int start=0);
    
    // Split a string on every occurrence of a given character
    extern function qs     split(string splitset);
    
    // Replace the range [l:r] with some other string, not necessarily same length
    extern function void   replace(int l, int r, string rs);
    
    // Return the n characters from position p. If p<0, count back from [length].
    extern function void   range(int p, int n);
    
    // Tokenize a string on whitespace boundaries
    extern function qs     tokens();
    
    // Trim a string (remove leading and/or trailing whitespace)
    extern function void   trim(side_e side=BOTH);
    
    // Justify a string (pad to width with spaces on left/right/both)
    extern function void   just(int width, side_e side=BOTH, side_e pre_trim=BOTH);
    
/*
    // Filename manipulations
    extern static function string str_fileJoin (qs components);
    extern static function qs     str_fileSplit(string path);
    extern static function string str_fileDir  (string path);
    extern static function string str_fileTail (string path);
    extern static function string str_fileExtn (string path);
    extern static function string str_fileBase (string path);
*/
    
    protected string value;
    
  endclass
  
  
    // Save a string as an object so that further manipulations can
    // be performed on it.  Get and set the object's string value.
    function Str    Str::create(string s = "");
      Str str = new();
      str.value = s;
      return str;
    endfunction
    
    function string Str::get();
      return value;
    endfunction
    
    function void Str::set(string s);
      value = s;
    endfunction
    
    function int Str::len();
      return value.len;
    endfunction
    
    // Find the first occurrence of substr in s, starting from the "start"
    // position. If a match is found, return the index of the first character
    // of the match.  If no match is found, return -1.
    function int Str::locate(string substr, int start=0);
      return -1;
    endfunction
    
    // Split a string on every occurrence of a given character
    function qs Str::split(string splitset);
      return {};
    endfunction
    
    // Replace the range [l:r] with some other string, not necessarily same length
    function void Str::replace(int l, int r, string rs);
    endfunction
    
    // Replace contents with the n characters from position p.
    // If p<0, count back from [length].
    // If n<0, take characters from (p+1-|n|) to (p).
    // If n>=0, take characters from (p) to (p+n-1).
    // In case of falling off either end of the string, 
    // take as much as possible up to and including the end.
    // If |p| >= [length], result is empty string.
    function void Str::range(int p, int n);
    endfunction
    
    // Tokenize a string on whitespace boundaries
    function qs Str::tokens();
      return {};
    endfunction
    
    // a string (remove leading and/or trailing whitespace)
    function void Str::trim(side_e side=BOTH);
      int first = 0;
      int last  = value.len-1;
      if (side inside {LEFT, BOTH}) begin
        while ((first <= last) && isspace(value[first])) first++;
      end
      if (side inside {RIGHT, BOTH}) begin
        while ((first <= last) && isspace(value[last])) last--;
      end
      value = value.substr(first, last);
    endfunction
  
    // Justify a string (pad to width with spaces on left/right/both)
    function void Str::just(int width, side_e side=BOTH, side_e pre_trim=BOTH);
      int n, n2;
      if (side == NONE) return;
      trim(pre_trim);
      n = width - signed'(value.len);
      if (n <= 0) return;
      case (side)
        RIGHT:
          value = { {n{" "}}, value };
        LEFT:
          value = { value, {n{" "}} };
        BOTH:
          begin
            n2 = n/2;
            value = { {n2{" "}}, value, {n-n/2{" "}} };
          end
      endcase
    endfunction
    
endpackage

`endif
