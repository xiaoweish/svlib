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
  
    typedef enum {NONE, LEFT, RIGHT, BOTH} side_e;
    typedef enum {START, END} origin_e;
  
    // Save a string as an object so that further manipulations can
    // be performed on it.  Get and set the object's string value.
    extern static  function Str    create(string s = "");
    extern virtual function string get();
    extern virtual function Str    copy();
    extern virtual function int    len();
    
    extern virtual function void   set(string s);
    
    extern virtual function void   append(string s);

    // Find the first occurrence of substr in s, starting from the "start"
    // position. If a match is found, return the index of the first character
    // of the match.  If no match is found, return -1.
    extern virtual function int    first(string substr, int ignore=0);
    extern virtual function int    last (string substr, int ignore=0);
    
    // Split a string on every occurrence of a given character
    extern virtual function qs     split(string splitset);
    
    // Get a range (substring). The starting position 'p' is an anchor point,
    // like an I-beam cursor, just to the left of the specified character.
    // If 'origin' is START, count 'p' from the left end of the string, 
    // with its value increasing towards the right. If 'origin' is END, 
    // count 'p' from the right end of the string, with its value increasing
    // towards the left.
    // The range size 'n' specifies a count of characters to the right of 'p',
    // or to the left of 'p' if 'n' is negative; n==0 specifies an empty string.
    // If p<0, treat it as the corresponding number of character positions
    // beyond the end (or start) of the string.
    // Clip result to smaller than n if necessary so that the result remains
    // entirely within the bounds of the original string.
    extern virtual function void   range(int p, int n, origin_e origin=START);
    
    // Replace the range p/n with some other string, not necessarily same length.
    // If n==0 this is an insert operation.
    extern virtual function void   replace(string rs, int p, int n, origin_e origin=START);
    
    // Tokenize a string on whitespace boundaries
    extern virtual function qs     tokens();
    
    // Trim a string (remove leading and/or trailing whitespace)
    extern virtual function void   trim(side_e side=BOTH);
    
    // Justify a string (pad to width with spaces on left/right/both)
    extern virtual function void   just(int width, side_e side=BOTH);
    
    protected string value;
    
    extern protected function void get_range_positions(
      int p, int n, origin_e origin=START,
      output int L, output int R
    );
    extern protected function void clip_to_bounds(inout int n);
    
  endclass
  
  class Regex extends svlib_base;
  
    localparam int maxSubMatches = 9;
  
    extern static  function Regex  create(string s = "", bit nocase=0, bit linestop=0);
    extern virtual function void   set(string s, bit nocase=0, bit linestop=0);
    extern virtual function void   setOpts(bit nocase, bit linestop);
    extern virtual function string get();
    extern virtual function void   getOpts(output bit nocase, output bit linestop);
    extern virtual function Regex  copy();
    
    extern virtual function int    run(Str s, output int nSubMatches, input int startPos=0);
    extern virtual function int    rerun(output int nSubMatches, input int startPos=0);
    
    extern virtual function int    getMatchPosition(int match, output int L, output int R);
    extern virtual function int    getMatchString(int match, output string s);
    extern virtual function int    getError();
    extern virtual function string getErrorString();
    
    protected Str last_run;
    
    protected int compiledRegexKey;        // for lookup on C side
    protected chandle compiledRegexHandle; // check on C-side pointer
    protected struct {int rm_so; int rm_eo;} rm[0:maxSubMatches];
  
  endclass
  
  
  function void Str::get_range_positions(
    int p, int n, origin_e origin=START,
    output int L, output int R
  );
    int len = value.len;
    // establish start position "just to the left of"
    if (origin==END) begin
      L = len - p;
    end
    else begin
      L = p;
    end
    // establish L/R boundaries
    R = L;
    if (n<0) begin
      // 'p' is right end, push L leftwards appropriately
      L += n;
    end
    else begin
      // 'p' is left end, push R rightwards appropriately
      R += n;
    end
  endfunction

  function void Str::clip_to_bounds(inout int n);
    if (n<0) n=0; else if (n>value.len) n=value.len;
  endfunction

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
  
  function Str Str::copy(); 
    return create(value);
  endfunction

  function void Str::set(string s);
    value = s;
  endfunction

  function void Str::append(string s);
    replace(s, 0, 0, END);
  endfunction


  // Find the first occurrence of substr in s, starting from the "start"
  // position. If a match is found, return the index of the first character
  // of the match.  If no match is found, return -1.
  function int Str::first(string substr, int ignore=0);
    for (int i=ignore; i<=(value.len-substr.len); i++) begin
      if (substr == value.substr(i, i+substr.len-1)) return i;
    end
    return -1;
  endfunction

  function int Str::last(string substr, int ignore=0);
    for (int i=(value.len-substr.len)-ignore; i>=0; i--) begin
      if (substr == value.substr(i, i+substr.len-1)) return i;
    end
    return -1;
  endfunction

  // Replace the range p/n with some other string, not necessarily same length
  function void Str::replace(string rs, int p, int n, origin_e origin=START);
    int len = value.len;
    int L, R;
    get_range_positions(p, n, origin, L, R);
    clip_to_bounds(L);
    clip_to_bounds(R);
    value = {value.substr(0, L-1), rs, value.substr(R, len-1)};
  endfunction
  //
  function automatic string str_replace(
      string orig, string rs, int p, int n=0, Str::origin_e origin=Str::START
    );
    Str obj = Obstack#(Str)::get();
    obj.set(orig);
    obj.replace(rs, p, n, origin);
    str_replace = obj.get();
    Obstack#(Str)::put(obj);
  endfunction

  function void Str::range(int p, int n, origin_e origin=START);
    int L, R;
    get_range_positions(p, n, origin, L, R);
    clip_to_bounds(L);
    clip_to_bounds(R);
    // adjust for substr conventions
    R--;
    value = value.substr(L, R);
  endfunction

  // Trim a string (remove leading and/or trailing whitespace)
  function void Str::trim(side_e side=BOTH);
    int first;
    int last;
    if (side == NONE) return;
    first = 0;
    last  = value.len-1;
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
    
  // Split a string on every occurrence of a given character
  function qs Str::split(string splitset);
    split = {};
    if (splitset == "") begin
      foreach (value[i]) split.push_back(value[i]);
    end
    else begin
      byte unsigned splitchars[$];
      int anchor = 0;
      foreach (splitset[i]) begin
        splitchars.push_back(splitset[i]);
      end
      foreach (value[i]) begin
        if (value[i] inside {splitchars}) begin
          split.push_back(value.substr(anchor, i-1));
          anchor = i+1;
        end
      end
      split.push_back(value.substr(anchor, value.len()-1));
    end
  endfunction

  // REVISIT Incomplete implementations:
  
  // Tokenize a string on whitespace boundaries. Commas and
  // string quotes are respected, CSV-fashion.
  function qs Str::tokens();
    return {};
  endfunction

  function Regex  Regex::create(string s = "", bit nocase=0, bit linestop=0);
  endfunction
  
  function void   Regex::set(string s, bit nocase=0, bit linestop=0);
  endfunction
  
  function void   Regex::setOpts(bit nocase, bit linestop);
  endfunction
  
  function string Regex::get();
  endfunction
  
  function void   Regex::getOpts(output bit nocase, output bit linestop);
  endfunction
  
  function Regex  Regex::copy();
  endfunction
  
  function int    Regex::run(Str s, output int nSubMatches, input int startPos=0);
  endfunction
  
  function int    Regex::rerun(output int nSubMatches, input int startPos=0);
  endfunction
  
  function int    Regex::getMatchPosition(int match, output int L, output int R);
  endfunction
  
  function int    Regex::getMatchString(int match, output string s);
  endfunction
  
  function int    Regex::getError();
  endfunction
  
  function string Regex::getErrorString();
  endfunction
  
    
endpackage

`endif
