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

/////////////////////////////////////////////////////////////////////////////

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

function automatic bit file_accessible(string path, ACCESS_MODE_E mode);
  int ok;
  svlibErrorManager errorManager = error_getManager();
  int err = svlib_dpi_imported_access(path, mode, ok);
  if (err) begin
    qs modes;
    ACCESS_MODE_E all_modes[$];
    all_modes = EnumUtils#(ACCESS_MODE_E)::all_values();
    foreach(all_modes[i]) begin
      if (mode & all_modes[i]) begin
        modes.push_back(all_modes[i].name);
      end
    end
    // special case for the oddball, known to be zero
    if (modes.size()==0) begin
      modes.push_back("accessEXISTS");
    end
    errorManager.submit(err, 
      $sformatf("file_accessible(%s, %s) failed", path, str_sjoin(modes, " | ")));
  end
  else begin
    errorManager.submit(0);
  end

  return ok;
endfunction


`include "svlib_impl_File.svh"

