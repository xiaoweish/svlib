function Pathname Pathname::create(string s = "");
endfunction

function string Pathname::render(int first, int last);
  if (!absolute || (first != 0)) begin
    return separator.sjoin(comps[first:last]);
  end
  else if (last < first) begin
    return volume();
  end
  else begin
    return {volume(), separator.sjoin(comps[first:last])};
  end
endfunction

function string Pathname::get();
  return render(0, comps.size()-1);
endfunction

function void Pathname::set(string path);
endfunction

function string Pathname::append(string tail);
endfunction

function Pathname Pathname::copy();
  Pathname result = Obstack#(Pathname)::obtain();
  result.comps = this.comps;
  result.absolute = this.absolute;
  result.value = this.value.copy();
endfunction

function void Pathname::purge();
  comps = {};
  absolute = 0;
  value.set("");
endfunction

function bit Pathname::isAbsolute();
  return absolute;
endfunction

function string Pathname::dirname(int backsteps=1);
  return render(0, comps.size()-(1+backsteps));
endfunction

function string Pathname::extension();
  string result = comps[$];
  Str str = Obstack#(Str)::obtain();
  int dotpos;
  str.set(result);
  dotpos = str.last(".");
  if (dotpos < 0) begin
    return "";
  end
  else begin
    Obstack#(Str)::relinquish(str);
    return result.substr(dotpos, result.len()-1);
  end
endfunction

function string Pathname::tail(int backsteps=1);
  return render(comps.size()-backsteps, comps.size()-1);
endfunction

function void Pathname::decompose();
  qs components = value.split("/", 0);
  absolute = (value.first("/") == 0);
  foreach (components[i])
    if (components[i] != "")
      comps.push_back(components[i]);
endfunction

function string Pathname::volume();  // always '/' on *nix
  return "/";
endfunction
