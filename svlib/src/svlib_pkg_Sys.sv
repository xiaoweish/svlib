typedef struct packed {
  bit r;
  bit w;
  bit x;
} sysFileRWX_s;

typedef struct packed {
  bit          setUID;
  bit          setGID;
  bit          sticky;
  sysFileRWX_s owner;
  sysFileRWX_s group;
  sysFileRWX_s others;
} sysFilePermissions_s;

typedef enum bit [3:0] {
  fTypeFifo    = 4'h1,
  fTypeCharDev = 4'h2,
  fTypeDir     = 4'h4,
  fTypeBlkDev  = 4'h6,
  fTypeFile    = 4'h8,
  fTypeSymLink = 4'hA,
  fTypeSocket  = 4'hC
} sysFileType_e;

typedef struct packed {
  sysFileType_e        fType;
  sysFilePermissions_s fPermissions;
} sysFileMode_s;

typedef struct {
  longint       mtime;
  longint       atime;
  longint       ctime;
  longint       size;
  sysFileMode_s mode;
} sys_fileStat_s;

function automatic string sys_formattedTime(
    input longint epochSeconds,
    input string  format
  );
  string result;
  if (format == "%Q") begin
    void'(svlib_dpi_imported_timeFormatST(epochSeconds, result));
  end
  else begin
    void'(svlib_dpi_imported_timeFormat(epochSeconds, format, result));
  end
  return result;
endfunction

function automatic longint sys_dayTime();
  longint result, junk_ns;
  svlib_dpi_imported_hiResTime(0, result, junk_ns);
  return result;
endfunction

function automatic longint unsigned sys_clockResolution();
  longint seconds, nanoseconds;
  svlib_dpi_imported_hiResTime(1, seconds, nanoseconds);
  return 1e9*seconds + nanoseconds;
endfunction

function automatic longint unsigned sys_nanoseconds();
  longint seconds, nanoseconds;
  svlib_dpi_imported_hiResTime(0, seconds, nanoseconds);
  return 1e9*seconds + nanoseconds;
endfunction

function automatic sys_fileStat_s sys_fileStat(string path, bit asLink=0);
  longint stats[statARRAYSIZE];
  int err;
  err = svlib_dpi_imported_fileStat(path, asLink, stats);
  if (errorManager.check(err)) begin
    fileStat_check_syscall_ok:
      assert (!err) else 
        $error("Failed to stat \"%s\": %s", 
                                path, svlibErrorDetails()
        );
  end
  if (!err) begin
    sys_fileStat.mtime = stats[statMTIME];
    sys_fileStat.atime = stats[statATIME];
    sys_fileStat.ctime = stats[statCTIME];
    sys_fileStat.size  = stats[statSIZE ];
    sys_fileStat.mode  = stats[statMODE ];
  end
endfunction

function automatic qs sys_fileGlob(string wildPath);
  qs      paths;
  chandle hnd;
  int     count;
  int     err;

  err = svlib_dpi_imported_globStart(wildPath, hnd, count);
  if (errorManager.check(err)) begin
    fileGlob_check_globStart_ok:
      assert (!err) else
        $error("Failed to glob \"%s\": %s", wildPath, svlibErrorDetails());
  end

  if (!err) begin
    err = svlib_private_getQS(hnd, paths);
    if (errorManager.check(err)) begin
      fileGlob_check_getQS_ok:
        assert (!err) else
         $error("Failed to get glob strings: %s", svlibErrorDetails());
    end
  end

  return paths;
endfunction
