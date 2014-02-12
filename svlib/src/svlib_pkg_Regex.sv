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

function bit scanVerilogInt(string s, inout logic signed [63:0] result);
  logic signed [63:0] value;
  Regex re;
  Str str;
  str = Obstack#(Str)::get();
  str.set(s);
  
  // First sieve: is it syntactically anything like an integer?
  re = Obstack#(Regex)::get();
  re.setRE("^[[:space:]]*(-?)[[:space:]]*(([[:digit:]]+)?'([hxdob]))?([[:xdigit:]xz_]+)[[:space:]]*$");
  re.setOpts(Regex::NOCASE);
  if (!re.test(str)) begin
    Obstack#(Str)::put(str);
    Obstack#(Regex)::put(re);
    return 0;
  end
  else begin
    string nBitsStr, radixLetter, valueStr, signStr;
    bit ok;
    int nBits;
    signStr     = re.getMatchString(1);
    nBitsStr    = re.getMatchString(3);
    radixLetter = re.getMatchString(4);
    valueStr    = re.getMatchString(5);
    
    if (nBitsStr == "")
      nBits = 32;
    else
      nBits = nBitsStr.atoi;
    ok = scanUint64(radixLetter, valueStr, value);
    // prune to width
    if (nBits < 64) value &= ((64'b1 << nBits) - 1);
    // now negate if necessary, so sign-ext is correct
    if (ok && (signStr == "-")) value = -value;
    if (ok) result = value;
    Obstack#(Regex)::put(re);
    Obstack#(Str)::put(str);
    return ok;
  end
endfunction


`include "svlib_impl_Regex.sv"
