// svlib_Regex_impl.sv
// ---------------------
// Implementations (bodies) of extern functions in class Regex
//
// This file is `include-d into svlib_Str_pkg.sv and
// should not be used in any other context.

function Regex  Regex::create(string s = "", int options=0);
  Regex r = Obstack#(Regex)::get();
  r.purge();
  r.text = s;
  r.options = options;
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
  return it;
endfunction

function int    Regex::test(Str s, int startPos=0);
  runStr = s;
  return retest(startPos);
endfunction

function int    Regex::retest(int startPos);
  int result;
  nMatches = -1;  // pessimistic, means "nothing done yet"

  lastError = svlib_dpi_imported_regexRun(
    .re(text), .str(runStr.get()), .options(options), .startPos(startPos), 
    .matchCount(nMatches), .matchList(matchList));
  assert (lastError == 0) else $error("whoops, RE error %0d (%s)", lastError,
  getErrorString());
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
    lastError = svlib_dpi_imported_regexRun(
      .re(text), .str(""), .options(options), .startPos(0), 
      .matchCount(nMatches), .matchList(matchList));
  end
  return lastError;
endfunction

function string Regex::getErrorString();
  case (lastError)
    0  : return "";
    -1 : return "svlib_regex not yet run";
    default :
      return svlib_dpi_imported_regexErrorString(lastError, text);
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
// were doubled. $_ and $& are treated as synonyms for $0.
//
function int Regex::match_subst(string substStr);
  qs  parts;
  Str realSubst = Obstack#(Str)::get();
  int i, result, m;
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
      if (parts[i] inside {["0":"9"], "&", "_"}) begin
        int m;
        if (parts[i] inside {"_", "&"}) 
          m = 0; // $& and $_ are synonyms for $0
        else
          m = parts[i].atoi();
        realSubst.append(getMatchString(m));
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
