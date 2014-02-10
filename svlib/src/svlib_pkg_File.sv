class Path extends Str;

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
