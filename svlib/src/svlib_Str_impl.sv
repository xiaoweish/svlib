// svlib_Str_impl.sv
// ---------------------
// Implementations (bodies) of extern functions in class Str
//
// This file is `include-d into svlib_Str_pkg.sv and
// should not be used in any other context.

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

// Pad a string to ~width~ with spaces on left/right/both
function void Str::pad(int width, side_e side=BOTH);
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
