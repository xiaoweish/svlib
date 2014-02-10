// Str: various string manipulations.
// Many functions come in two flavors:
// - a package version named str_XXX that takes a string value,
//   does some work on it and returns a result; and
// - an object version named .XXX that operates on a stored
//   Str object, possibly returning a result and possibly
//   modifying the stored object.
//
class Str extends svlibBase;

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

  // Pad a string to width with spaces on left/right/both
  extern virtual function void   pad   (int width, side_e side=BOTH);

  protected string value;
  protected function void setClean(string s);
    // Zap all to initial state except for "value"
    value = s;
  endfunction

  extern protected function void get_range_positions(
    int p, int n, origin_e origin=START,
    output int L, output int R
  );
  extern protected function void clip_to_bounds(inout int n);

endclass

class Regex extends svlibBase;

  typedef enum {NOCASE=regexNOCASE, NOLINE=regexNOLINE} regexOptions;

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

function automatic string str_pad(string s, int width, Str::side_e side=Str::BOTH);
  Str str = Obstack#(Str)::get();
  str.set(s);
  str.pad(width, side);
  str_pad = str.get();
  Obstack#(Str)::put(str);
endfunction

  // Replace the range p/n with some other string, not necessarily same length.
  // If n==0 this is an insert operation.
function automatic string str_replace(string s, string rs, int p, int n,
                                      Str::origin_e origin=Str::START);
  Str str = Obstack#(Str)::get();
  str.set(s);
  str.replace(rs, p, n, origin);
  str_replace = str.get();
  Obstack#(Str)::put(str);
endfunction

//--------------------------------------------------------------

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
  re.setRE("^[[:space:]]*(([[:digit:]]+)?'([hxdob]))?([[:xdigit:]xz_]+)[[:space:]]*$");
  re.setOpts(Regex::NOCASE);
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

`include "svlib_Str_impl.sv"
`include "svlib_Regex_impl.sv"
