//=============================================================================
//  @brief  
//  @author Jonathan Bromley, Verilab (www.verilab.com)
// =============================================================================
//
//                      svlib SystemVerilab Utilities Library
//
// @File: svlib_pkg_Sys.svh
//
// Copyright 2014 Verilab, Inc.
// 
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
//=============================================================================
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
} sysFileType_enum;

typedef struct packed {
  sysFileType_enum     fType;
  sysFilePermissions_s fPermissions;
} sysFileMode_s;

typedef struct {
  longint       mtime;
  longint       atime;
  longint       ctime;
  longint       size;
  int unsigned  uid;
  int unsigned  gid;
  sysFileMode_s mode;
} sys_fileStat_s;

function automatic string sys_formatTime(
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

function automatic longint unsigned sys_nsTime();
  longint seconds, nanoseconds;
  svlib_dpi_imported_hiResTime(0, seconds, nanoseconds);
  return 1e9*seconds + nanoseconds;
endfunction

function automatic sys_fileStat_s sys_fileStat(string path, bit asLink=0);
  longint stats[statARRAYSIZE];
  int err;
  svlibErrorManager errorManager = error_getManager();
  err = svlib_dpi_imported_fileStat(path, asLink, stats);
  if (err) begin
    errorManager.submit(err, 
      $sformatf("sys_fileStat(.path(%s), .asLink(%b)): error in system call",
                       str_quote(path),       asLink));
  end
  else begin
    errorManager.submit(0);
    sys_fileStat.mtime = stats[statMTIME];
    sys_fileStat.atime = stats[statATIME];
    sys_fileStat.ctime = stats[statCTIME];
    sys_fileStat.size  = stats[statSIZE ];
    sys_fileStat.mode  = stats[statMODE ];
    sys_fileStat.uid   = stats[statUID  ];
    sys_fileStat.gid   = stats[statGID  ];
  end
endfunction

function automatic qs sys_fileGlob(string wildPath);
  qs      paths;
  chandle hnd;
  int     count;
  int     err;
  svlibErrorManager errorManager = error_getManager();

  err = svlib_dpi_imported_globStart(wildPath, hnd, count);
  if (err) begin
    errorManager.submit(err,
      $sformatf("error in sys_fileGlob(\"%s\")", wildPath));
  end
  else begin
    err = svlib_private_getQS(hnd, paths);
    if (err) begin
      errorManager.submit(err, 
        $sformatf("DPI fail getting result strings from sys_fileGlob(\"%s\"", wildPath));
    end
    else begin
      errorManager.submit(0);
    end
  end

  return paths;
endfunction

function automatic string sys_getEnv(string envVar);
  string envStr;
  if (svlib_dpi_imported_getenv(envVar, envStr) == 0) begin
    return envStr;
  end
  else begin
    return "";
  end
endfunction

function automatic bit    sys_hasEnv(string envVar);
  string envStr;
  return (svlib_dpi_imported_getenv(envVar, envStr) == 0);
endfunction

function automatic string sys_getCwd();
  string cwd;
  int err;
  svlibErrorManager errorManager = error_getManager();
  
  err = svlib_dpi_imported_getcwd(cwd);
  if (err) begin
    cwd = "";
    errorManager.submit(err, "error in sys_getcwd()");
  end
  else begin
    errorManager.submit(0);
  end
  
  return cwd;
endfunction
