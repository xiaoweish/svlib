`ifndef SVLIB_STR_PKG__DEFINED
`define SVLIB_STR_PKG__DEFINED

`include "svlib_macros.sv"


package svlib_Str_pkg;

  import svlib_Base_pkg::*;

  import "DPI-C" function int SvLib_regexRun(
                           input  string re,
                           input  string str,
                           input  int    options,
                           input  int    startPos,
                           output int    matchCount,
                           output int    matchList[]);
  import "DPI-C" function string SvLib_regexErrorString(input int err, input string re);

  // Str: various string manipulations.
  // Most functions come in two flavors:
  // - a package version named str_XXX that takes a string value,
  //   does some work on it and returns a result; and
  // - an object version named .XXX that operates on a stored
  //   Str object, possibly returning a result and possibly
  //   modifying the stored object.
  //
  class Str extends svlibBase;
  
    `SVLIB_CLASS_UTILS(Str)
  
    typedef enum {NONE, LEFT, RIGHT, BOTH} side_e;
    typedef enum {START, END} origin_e;
  
    // Save a string as an object so that further manipulations can
    // be performed on it.  Get and set the object's string value.
    extern static  function Str    create(string s = "");
    extern virtual function string get   ();
    extern virtual function Str    copy  ();
    extern virtual function int    len   ();
    
    extern virtual function void   set   (string s);
    extern virtual function void   append(string s);

    // Find the first occurrence of substr in s, ignoring the specified
    // number of characters from the starting point.
    // If a match is found, return the index of the leftmost
    // character of the match.
    // If no match is found, return -1.
    extern virtual function int    first (string substr, int ignore=0);
    extern virtual function int    last  (string substr, int ignore=0);
    
    // Split a string on every occurrence of a given character
    extern virtual function qs     split (string splitset="", bit keepSplitters=0);
    
    // Use the Str object's contents to join adjacent elements of the 
    // queue of strings into a single larger string. For example, if the
    // Str object 's' contains "XX" then
    //    s.sjoin({"a", "b", "c"})
    // would yield the string "a, b, c"
    extern virtual function string sjoin (qs strings);
    
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
    extern virtual function string range (int p, int n, origin_e origin=START);
    
    // Replace the range p/n with some other string, not necessarily same length.
    // If n==0 this is an insert operation.
    extern virtual function void   replace(string rs, int p, int n, origin_e origin=START);
    
    // Trim a string (remove leading and/or trailing whitespace)
    extern virtual function void   trim  (side_e side=BOTH);
    
    // Justify a string (pad to width with spaces on left/right/both)
    extern virtual function void   just  (int width, side_e side=BOTH);
    
    protected string value;
    
    extern protected function void get_range_positions(
      int p, int n, origin_e origin=START,
      output int L, output int R
    );
    extern protected function void clip_to_bounds(inout int n);
    
  endclass
  
  class Regex extends svlibBase;
  
    `SVLIB_CLASS_UTILS(Regex)
  
    typedef enum {NOCASE=1, NOLINE=2} regexOptions;
    
    extern static  function Regex  create (string s = "", int options=0);
    // Set the regular expression string
    extern virtual function void   setRE  (string s);
    // Set the options (as a bitmap)
    extern virtual function void   setOpts(int options);
    // Set the test string
    extern virtual function void   setStr (Str s);
    extern virtual function void   setStrContents (string s);
    
    // Retrieve the regex string
    extern virtual function string getRE  ();
    // Retrieve the option bitmap
    extern virtual function int    getOpts();
    // Retrieve the test string
    extern virtual function string getStr ();

    // Clone this regex into another, preserving all values
    extern virtual function Regex  copy   ();

    // Get the error code for the most recent error. 
    // Checks the RE for validity, if not done already.    
    extern virtual function int    getError();
    // Get a string representation of the error
    extern virtual function string getErrorString();
    
    // Run the RE on a sample string, skipping over the first startPos characters
    extern virtual function int    test   (Str s, int startPos=0);
    // Run the RE again on the same sample string, with different start position
    extern virtual function int    retest (int startPos);
    
    // From the most recent test, find how many matches there were (0=no match).
    // The whole match counts as 1; each submatch/group adds one.
    extern virtual function int    getMatchCount ();
    // For a given match (0=full) get the start position of that match
    extern virtual function int    getMatchStart (int match);
    // For a given match (0=full) get the length of that match
    extern virtual function int    getMatchLength(int match);
    // Extract a given match from the sample string, returns "" if no match
    extern virtual function string getMatchString(int match);
    
    extern virtual function int    subst(Str s, string substStr, int startPos = 0);
    extern virtual function int    substAll(Str s, string substStr, int startPos = 0);
    
    extern protected virtual function void   purge();
    extern protected virtual function int    match_subst(string substStr);
    
    protected int nMatches;
    protected int lastError;
    protected int matchList[20];
    protected Str runStr;
    
    //protected int     compiledRegexKey;    // for lookup on C side
    //protected chandle compiledRegexHandle; // check on C-side pointer
    
    protected int    options;
    protected string text;
  
  endclass
  
  
  class Path extends Str;
  
    `SVLIB_CLASS_UTILS(Path)

    extern static function bit    isAbsolute    (string path);
    extern static function string dirname       (string path, int backsteps=1);
    extern static function string extension     (string path);
    extern static function string tail          (string path, int backsteps=1);
    extern static function string commonAncestor(string path, string other);
    extern static function string relPathTo     (string path, string other);
    extern static function string normalize     (string path);
    extern static function qs     decompose     (string path);
    extern static function string compose       (qs subpaths);
    extern static function string volume        (string path);  // always '/' on *nix
  endclass
  
  function automatic bit isspace(byte unsigned ch);
    return (ch inside {"\t", "\n", " ", 13, 160});  // CR, nbsp
  endfunction
  
  function automatic string str_sjoin(qs elements, string joiner);
    Str str = Obstack#(Str)::get();
    str.set(joiner);
    str_sjoin = str.sjoin(elements);
    Obstack#(Str)::put(str);
  endfunction
  
  function automatic string str_repeat(string s, int n);
    if (n<=0) return "";
    return {n{s}};
  endfunction
  
  function automatic string str_trim(string s, Str::side_e side=Str::BOTH);
    Str str = Obstack#(Str)::get();
    str.set(s);
    str.trim(side);
    str_trim = str.get();
    Obstack#(Str)::put(str);
  endfunction
  
  function automatic Regex regexMatch(string haystack, string needle, int options=0);
    Regex re;
    Str   s;
    bit   found;
    re  = Obstack#(Regex)::get();
    re.setRE(needle);
    re.setOpts(options);
    regexMatch_check_RE_valid: 
      assert (re.getError()==0) else
        $error("Bad RE \"%s\": %s", needle, re.getErrorString());
    s   = Str::create(haystack);
    found = re.test(s);
    if (found)
      return re;
    // Return the unwanted Regex object to the obstack
    Obstack#(Regex)::put(re);
    return null;
  endfunction

  // REVISIT: negative numbers must be accepted
  function bit scanVerilogInt(string s, output integer result);
    Regex re;
    Str str;
    re = Obstack#(Regex)::get();
    str = Obstack#(Str)::get();
    str.set(s);
    // First sieve: is it syntactically anything like an integer?
    re.setRE("^[[:space:]]*(([[:digit:]]+)?'([hHxXdDoObB]))?([[:xdigit:]_]+)[[:space:]]*$");
    if (!re.test(str)) begin
      Obstack#(Str)::put(str);
      Obstack#(Regex)::put(re);
      return 0;
    end
    else begin
      string nBitsStr, radixLetter, valueStr;
      bit ok;
      int nBits;
      nBitsStr    = re.getMatchString(2);
      radixLetter = re.getMatchString(3);
      valueStr    = re.getMatchString(4);
      if (nBitsStr == "")
        nBits = 32;
      else
        nBits = nBitsStr.atoi;
      ok = scanInt(radixLetter, valueStr, result);
      Obstack#(Regex)::put(re);
      Obstack#(Str)::put(str);
      return ok;
    end
  endfunction
  
  function bit scanInt(string radixLetter, string v, output integer result);
    int radix;
    case (radixLetter)
      "h", "H", "x", "X" :
        radix= 16;
      "o", "O" :
        radix = 8;
      "d", "D" , "" :
        radix = 10;
      "b", "B" :
        radix = 2;
      default :
        return 0;
    endcase
    if (radix == 16) begin
      result = v.atohex();
      return 1;
    end
    ///////////////////// REVISIT error checking for illegal digits
    case (radix)
      10: result = v.atoi();
       8: result = v.atooct();
       2: result = v.atobin();
     endcase
     return 1;
  endfunction

  /////////////////////// IMPLEMENTATIONS OF EXTERN METHODS ///////////////////
  
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
    Str result = Str::randstable_new();
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

  function string Str::range(int p, int n, origin_e origin=START);
    int L, R;
    get_range_positions(p, n, origin, L, R);
    clip_to_bounds(L);
    clip_to_bounds(R);
    // adjust for substr conventions
    R--;
    return value.substr(L, R);
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
        value = { str_repeat(" ", n), value };
      LEFT:
        value = { value, str_repeat(" ", n) };
      BOTH:
        begin
          n2 = n/2;
          value = { str_repeat(" ", n2), value, str_repeat(" ", n-n2) };
        end
    endcase
  endfunction
    
  // Split a string on every occurrence of a given character
  function qs Str::split(string splitset="", bit keepSplitters=0);
    split = {};
    if (splitset == "") begin
      for (int i=0; i<value.len(); i++) begin
        split.push_back(value.substr(i,i));
      end
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
          if (keepSplitters) begin
            split.push_back(value.substr(i,i));
          end
          anchor = i+1;
        end
      end
      split.push_back(value.substr(anchor, value.len()-1));
    end
  endfunction
  
  function string Str::sjoin(qs strings);
    string result;
    foreach (strings[i]) begin
      if (i>0) begin
        result = {result, value, strings[i]};
      end
      else begin
        result = {result, strings[i]};
      end
    end
    return result;
  endfunction

  function Regex  Regex::create(string s = "", int options=0);
    Regex r = Regex::randstable_new();
    r.setRE(s);
    r.setOpts(options);
    return r;
  endfunction
  
  function void   Regex::setRE(string s);
    if (s!=text) begin
      // RE text has changed, so we must reset the object
      this.text = s;
      purge();
    end
  endfunction
  
  function void   Regex::setOpts(int options);
    if (options!=this.options) begin
      // Something has changed, so we must reset the object
      this.options = options;
      purge();
    end
  endfunction
  
  function void   Regex::purge();
    //compiledRegexHandle = null;
    nMatches  = -1; // Not matched at all
    lastError = -1; // No match attempt
  endfunction
  
  function string Regex::getRE();
    return text;
  endfunction
  
  function string Regex::getStr();
    if (runStr == null)
      return "";
    else
      return runStr.get();
  endfunction
  
  function void Regex::setStr(Str s);
    runStr = s;
  endfunction
  
  function void Regex::setStrContents(string s);
    if (runStr == null)
      runStr = Obstack#(Str)::get();
    runStr.set(s);
  endfunction
  
  function int    Regex::getOpts();
    return options;
  endfunction
  
  function Regex  Regex::copy();
    Regex it = create(text, options);
  endfunction
  
  function int    Regex::test(Str s, int startPos=0);
    runStr = s;
    return retest(startPos);
  endfunction
  
  function int    Regex::retest(int startPos);
    int result;
    nMatches = -1;  // pessimistic, means "nothing done yet"
    
    lastError = SvLib_regexRun(
      .re(text), .str(runStr.get()), .options(options), .startPos(startPos), 
      .matchCount(nMatches), .matchList(matchList));
    if (nMatches<0 || nMatches>20) return 0;
    for (int i=2*nMatches; i<$size(matchList,1); i++) matchList[i] = -1;
    return (lastError==0 && nMatches>0);
  endfunction
  
  function int    Regex::getMatchCount();
    return nMatches;
  endfunction
  
  function int    Regex::getMatchStart(int match);
    if (match>nMatches || match<0) begin
      return -1;
    end
    else begin
      return matchList[match*2];
    end
  endfunction
  
  function int    Regex::getMatchLength(int match);
    if (match>nMatches || match<0) begin
      return 0;
    end
    else begin
      return matchList[match*2+1] - matchList[match*2];
    end
  endfunction
  
  function string    Regex::getMatchString(int match);
    int L, len;
    L = getMatchStart(match);
    if (L<0) return "";
    if (runStr == null) return "";
    len = getMatchLength(match);
    if (len<=0) return "";
    return runStr.range(L, len);
  endfunction
  
  function int Regex::getError();
    if (lastError < 0) begin
      lastError = SvLib_regexRun(
        .re(text), .str(""), .options(options), .startPos(0), 
        .matchCount(nMatches), .matchList(matchList));
    end
    return lastError;
  endfunction
  
  function string Regex::getErrorString();
    case (lastError)
      0  : return "";
      -1 : return "SvLib_regex not yet run";
      default :
        return SvLib_regexErrorString(lastError, text);
    endcase
  endfunction
  
  function int Regex::subst(Str s, string substStr, int startPos = 0);
    if (test(s, startPos)) begin 
      startPos = match_subst(substStr);
      return 1;
    end
    else begin
      return 0;
    end
  endfunction

  function int Regex::substAll(Str s, string substStr, int startPos = 0);
    int n = 0;
    while (test(s, startPos)) begin
      startPos = match_subst(substStr);
      n++;
    end
    return n;
  endfunction
  
  // Internal "works" of subst for a single match, assumed already matched.
  // Replaces $0..$9 with the corresponding submatches; $ followed by any 
  // other character is replaced with the second character literally. $ at
  // the very end of the replacement string acts as a literal $, as if it
  // were doubled.
  //
  function int Regex::match_subst(string substStr);
    qs  parts;
    Str realSubst = Obstack#(Str)::get();
    int i, result;
    realSubst.set(substStr);
    parts = realSubst.split("");
    realSubst.set("");
    i = 0;
    while (i<parts.size()) begin
      if ((i == parts.size()-1) || (parts[i] != "$")) begin
        realSubst.append(parts[i]);
      end
      else begin
        i++;
        if (parts[i] inside {["0":"9"]}) begin
          int m = parts[i].atoi();
          realSubst.append(runStr.range(getMatchStart(m), getMatchLength(m)));
        end
        else begin
          realSubst.append(parts[i]);
        end
      end
      i++;
    end
    runStr.replace(realSubst.get(), getMatchStart(0), getMatchLength(0));
    result = getMatchStart(0) + realSubst.len();
    Obstack#(Str)::put(realSubst);
    return result;
  endfunction

  /////////////////////////////////////////////////////////////////////////////
    
  function bit Path::isAbsolute(string path);
    return (path[0] == "/");
  endfunction
  
  function string Path::dirname(string path, int backsteps=1);
    qs comps = decompose(path);
    if (backsteps >= comps.size()) begin
      return path;
    end
    else begin
      return compose(comps[0:(comps.size()-1)-backsteps]);
    end
  endfunction

  function string Path::extension(string path);
    string result = tail(path);
    Str str = Obstack#(Str)::get();
    int dotpos;
    str.set(result);
    dotpos = str.last(".");
    if (dotpos < 0) begin
      return "";
    end
    else begin
      Obstack#(Str)::put(str);
      return result.substr(dotpos, result.len()-1);
    end
  endfunction

  function string Path::tail(string path, int backsteps=1);
    qs comps = decompose(path);
    if (backsteps >= comps.size()) begin
      return path;
    end
    else begin
      return compose(comps[comps.size()-backsteps:comps.size()-1]);
    end
  endfunction

  function string Path::commonAncestor(string path, string other);
    qs compsP = decompose(normalize(path));
    qs compsO = decompose(normalize(other));
  endfunction

  function string Path::relPathTo(string path, string other);
  endfunction

  function string Path::normalize(string path);
    qs comps = decompose(path);
  endfunction

  function qs Path::decompose(string path);
    qs components, result;
    Str pstr = Obstack#(Str)::get();
    pstr.set(path);
    components = pstr.split("/", 0);
    Obstack#(Str)::put(pstr);
    if (isAbsolute(path))
      result.push_back("/");
    foreach (components[i])
      if (components[i] != "")
        result.push_back(components[i]);
    return result;
  endfunction

  function string Path::compose(qs subpaths);
    string result;
    qs  pathComps;
    int firstUseful = 0;
    Str path = Obstack#(Str)::get();
    bit notFirst = 0;
    path.set("");
    for (int i=subpaths.size()-1; i>=0; i--) if (isAbsolute(subpaths[i])) begin
      firstUseful=i;
      break;
    end
    for (int i=firstUseful; i<subpaths.size(); i++) begin
      pathComps = decompose(subpaths[i]);
      foreach (pathComps[j]) begin
        if (notFirst) begin
          path.append("/");
        end
        notFirst = 1;
        path.append(pathComps[j]);
      end
    end
    result = path.get();
    Obstack#(Str)::put(path);
    return result;
  endfunction
  
  function string Path::volume(string path);  // always '/' on *nix
    return "/";
  endfunction
  
endpackage

`endif
