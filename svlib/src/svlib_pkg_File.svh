class Pathname extends svlibBase;

  extern static function Pathname create(string s = "");

  extern virtual function string   get           ();
  extern virtual function bit      isAbsolute    ();
  extern virtual function string   dirname       (int backsteps=1);
  extern virtual function string   extension     ();
  extern virtual function string   basename      ();
  extern virtual function string   tail          (int backsteps=1);
  extern virtual function string   volume        ();  // always '/' on *nix
  
  extern virtual function Pathname copy          ();
  extern virtual function void     set           (string path);
  extern virtual function void     append        (string tail);
  extern virtual function void     appendPN      (Pathname tailPN);
  
  // forbid construction
  protected function new(); endfunction
  extern protected virtual function void   purge();
  extern protected virtual function string render(int first, int last);

  protected qs  comps;
  protected bit absolute;
  static protected Str separator = Str::create("/");

endclass

function automatic longint file_mTime(string path, bit asLink=0);
  sys_fileStat_s stat = sys_fileStat(path, asLink);
  return stat.mtime;
endfunction

function automatic longint file_aTime(string path, bit asLink=0);
  sys_fileStat_s stat = sys_fileStat(path, asLink);
  return stat.atime;
endfunction

function automatic longint file_cTime(string path, bit asLink=0);
  sys_fileStat_s stat = sys_fileStat(path, asLink);
  return stat.ctime;
endfunction

function automatic longint file_size(string path, bit asLink=0);
  sys_fileStat_s stat = sys_fileStat(path, asLink);
  return stat.size;
endfunction

function automatic longint file_mode(string path, bit asLink=0);
  sys_fileStat_s stat = sys_fileStat(path, asLink);
  return stat.mode;
endfunction


/////////////////////////////////////////////////////////////////////////////

`include "svlib_impl_File.svh"

