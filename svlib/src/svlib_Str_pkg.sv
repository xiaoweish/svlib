`ifndef SVLIB_STR_PKG__DEFINED
`define SVLIB_STR_PKG__DEFINED

`include "svlib_macros.sv"

package svlib_Str_pkg;

  typedef string qs[$];
  
  function automatic bit isspace(byte unsigned ch);
    return (ch inside {"\t", "\n", "\r", " ", 160});  // nbsp
  endfunction
  
  virtual class svlib_base;
    protected svlib_base obstack_link;
  endclass
  
  class Obstack #(parameter type T=int) extends svlib_base;
    local static svlib_base head;
    local static int constructed_ = 0;
    local static int get_calls_ = 0;
    local static int put_calls_ = 0;
    
    static function T get();
      T result;
      if (head == null) begin
        result = T::create();
        constructed_++;
      end
      else begin
        $cast(result, head);
        head = head.obstack_link;
      end
      get_calls_++;
      return result;
    endfunction
    static function void put(T t);
      put_calls_++;
      if (t == null) return;
      t.obstack_link = head;
      head = t;
    endfunction
    // debug/test only - DO NOT USE normally
    static function void stats(
        output int depth,
        output int constructed,
        output int get_calls,
        output int put_calls
      );
      svlib_base p = head;
      depth = 0;
      while (p != null) begin
        depth++;
        p = p.obstack_link;
      end
      constructed = constructed_;
      get_calls = get_calls_;
      put_calls = put_calls_;
    endfunction
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
  
    protected static Str obstack;
  
    typedef enum {NONE, LEFT, RIGHT, BOTH} side_e;
    typedef enum {START, END} origin_e;
  
    // Save a string as an object so that further manipulations can
    // be performed on it.  Get and set the object's string value.
    extern static  function Str    create(string s = "");
    extern virtual function string get();
    extern virtual function int    len();
    
    extern virtual function void   set(string s);
    // Find the first occurrence of substr in s, starting from the "start"
    // position. If a match is found, return the index of the first character
    // of the match.  If no match is found, return -1.
    
    extern virtual function void   append(string s);
    extern virtual function void   insert(string s, int where=0, origin_e origin=START);

    extern virtual function int    locate(string substr, int start=0, origin_e origin=START);
    
    // Split a string on every occurrence of a given character
    extern virtual function qs     split(string splitset);
    
    // Replace the range [l:r] with some other string, not necessarily same length
    extern virtual function void   replace(int l, int r, string rs);
    
    extern virtual function void   range(int p, int n);
    
    // Tokenize a string on whitespace boundaries
    extern virtual function qs     tokens();
    
    // Trim a string (remove leading and/or trailing whitespace)
    extern virtual function void   trim(side_e side=BOTH);
    
    // Justify a string (pad to width with spaces on left/right/both)
    extern virtual function void   just(int width, side_e side=BOTH);
    
    protected string value;
    
  endclass
  
  
  // Save a string as an object so that further manipulations can
  // be performed on it.
  function Str Str::create(string s = "");
    std::process p = std::process::self();
    string randstate = p.get_randstate();
    Str result = new();
    p.set_randstate(randstate);
    result.set(s);
    return result;
  endfunction

  // Get the object's string value.
  function string Str::get();
    return value;
  endfunction

  // Get the string's length.
  function int Str::len();
    return value.len;
  endfunction

  function void Str::set(string s);
    value = s;
  endfunction

  function void Str::append(string s);
    insert(s, 0, END);
  endfunction

  function void Str::insert(string s, int where=0, origin_e origin=START);
    int len = value.len;
    if (where < 0)
      where = 0;
    else if (where > len)
      where = len;
    if (origin == END)
      where = len - where;
    value = {value.substr(0, where-1), s, value.substr(where, len-1)};
  endfunction
  //
  function automatic string str_insert(
      string orig, string s, int where=0, Str::origin_e origin=Str::START
    );
    Str obj = Obstack#(Str)::get();
    obj.set(orig);
    obj.insert(s, where, origin);
    str_insert = obj.get();
    Obstack#(Str)::put(obj);
  endfunction

  // Find the first occurrence of substr in s, starting from the "start"
  // position. If a match is found, return the index of the first character
  // of the match.  If no match is found, return -1.
  function int Str::locate(string substr, int start=0, origin_e origin=START);
    return -1;
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

  // Split a string on every occurrence of a given character
  function qs Str::split(string splitset);
    return {};
  endfunction

  // Tokenize a string on whitespace boundaries
  function qs Str::tokens();
    return {};
  endfunction

  // Trim a string (remove leading and/or trailing whitespace)
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
  function void Str::just(int width, side_e side=BOTH);
    int n, n2;
    if (side == NONE) return;
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
