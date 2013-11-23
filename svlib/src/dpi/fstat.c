#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <glob.h>
#include <time.h>

#include <veriuser.h>
#include <svdpi.h>

#define STRINGIFY(x) MACROHASH(x)
#define MACROHASH(x) #x

#define SVLIB_STRING_BUFFER_START_SIZE       (256)
#define SVLIB_STRING_BUFFER_LONGEST_PATHNAME (8192)

#ifdef _CPLUSPLUS
extern "C" {
#endif

static char* libStringBuffer = NULL;
static int   libStringBufferSize = 0;

// Get a new string buffer of given size.
// If size<=0 and there is currently no buffer,
// create one with the default size. If size=0 and
// there is already a buffer, return it. If size<0
// and there is already a buffer, double its existing
// size and then return it.
//
static char* getLibStringBuffer(int size) {
  if (size<=0) {
    if (libStringBuffer==NULL) {
      return getLibStringBuffer(SVLIB_STRING_BUFFER_START_SIZE);
    } else if (size == 0) {
      return libStringBuffer;
    } else {
      return getLibStringBuffer(2*libStringBufferSize);
    }
  } else if (libStringBufferSize < size) {
    char* buf = malloc(size);
    if (buf == NULL) {
      perror("PROBLEM in SvLib::getLibStringBuffer: cannot malloc");
      // and return the existing buffer, whatever it is
    } else {
      free(libStringBuffer);
      libStringBuffer = buf;
      libStringBufferSize = size;
    }
  }
  return libStringBuffer;
}

static int getLibStringBufferSize() {
  if (libStringBuffer==NULL) {
    return 0;
  } else {
    return libStringBufferSize;
  }
}

//--------------------------------------------------------------------------
// FOR INTERNAL USE BY SVLIB ONLY:
// Mechanism to retrieve an array of strings from C into SV.
// A function such as 'glob' whose main result is an array of strings
// will construct such an array in internal storage here, then return
// a chandle pointing to the sa_buf_struct that records the array of strings
// and the SvLib's progress through collecting them.
// Subsequent calls to SvLib_saBufNext with this chandle will then
// serve up the strings one by one, finally returning with the chandle set
// to null to indicate that all the strings have been consumed and the 
// C-side internal storage has been freed and is no longer accessible.

// Each different data source will require its own free function.
typedef void (*freeFunc_decl)(saBuf_p);

typedef struct saBuf {
  char **        scan;         // pointer to the current array element
  freeFunc_decl  freeFunc;     // function to call on exhaustion
  void *         data_ptr;     // pointer to app-specific data
  struct saBuf * sanity_check; // pointer-to-self for checking
} saBuf_s, *saBuf_p;

static int saBufCreate(int dataBytes, freeFunc_decl ff, saBuf_p *created) {
  *created = NULL;
  saBuf_p sa = malloc(sizeof(saBuf_s));
  if (sa == NULL) {
    return ENOMEM;
  }
  sa->data_ptr = malloc(dataBytes);
  if (sa->data_ptr == NULL) {
    free(sa);
    return ENOMEM;
  }
  sa->sanity_check = sa;
  sa->freeFunc = ff;
  sa->scan = NULL;
  *created = sa;
  return 0;
}

//-------------------------------------------------------------------------------
// import "DPI-C" function int SvLib_saBufNext(inout chandle h, output string s);
//-------------------------------------------------------------------------------

extern int SvLib_saBufNext(void **h, const char **s) {
  *s = NULL;
  if (*h == NULL) {
    return 0;
  }
  saBuf_p p = (saBuf_p)(*h);
  if (p->sanity_check != p) {
    return ENOMEM;
  }
  *s = *(p->scan);
  p->scan++;
  if (*s == NULL) {
    *h = NULL;
    if (p->freeFunc != NULL) {
      (*(p->freeFunc))(p);
    }
  }
  return 0;
}

//-------------------------------------------------------------------
// import "DPI-C" function string SvLib_getCErrStr(input int errnum);
//-------------------------------------------------------------------

extern const char* SvLib_getCErrStr(int errnum) {
  return strerror(errnum);
}

//----------------------------------------------------------------
// import "DPI-C" function int SvLib_getcwd(output string result);
//----------------------------------------------------------------

extern int SvLib_getcwd(char ** p_result) {

  int  bSize = SVLIB_STRING_BUFFER_START_SIZE;
  char *buf;

  while (1) {
    buf   = getLibStringBuffer(bSize);
    bSize = getLibStringBufferSize();
    if (NULL != getcwd(buf, bSize)) {
      *p_result = buf;
      return 0;
    } else if (errno==ERANGE) {
      if (bSize >= SVLIB_STRING_BUFFER_LONGEST_PATHNAME) {
        *p_result = "Working directory pathname exceeds maximum buffer length " 
                    STRINGIFY(SVLIB_STRING_BUFFER_LONGEST_PATHNAME);
        return errno;
      } else {
        bSize *= 2;
      }
    } else {
      *p_result = strerror(errno);
      return errno;
    }
  }
}

//----------------------------------------------------------------
// import "DPI-C" function int SvLib_timeFormat(
//                                       input  string format, 
//                                       input  int    time, 
//                                       output string formatted);
//----------------------------------------------------------------

extern int SvLib_timeFormat(int t, const char *fs, const char ** p_result) {
  
  int  bSize = SVLIB_STRING_BUFFER_START_SIZE;
  char *buf;
  
  // There is no way to determine overflow error unless we can 
  // guarantee the result string is non-empty. So we prefix the
  // result string with a space to ensure non-emptiness. Ugh.
  char * fss = malloc(strlen(fs)+2);
  *fss = ' ';
  strcpy(&(fss[1]), fs);  

  while (1) {
    buf   = getLibStringBuffer(bSize);
    bSize = getLibStringBufferSize();
    if (0 != strftime(buf, bSize, fss, localtime(&t))) {
      *p_result = &(buf[1]); // skip added space
      free(fss);
      return 0;
    } else if (bSize >= SVLIB_STRING_BUFFER_LONGEST_PATHNAME) {
      *p_result = "timeFormat result exceeds maximum buffer length " 
                  STRINGIFY(SVLIB_STRING_BUFFER_LONGEST_PATHNAME);
      free(fss);
      return ERANGE;
    } else {
      bSize *= 2;
    }
  }
}

//----------------------------------------------------------------
//   import "DPI-C" function int SvLib_globStart(
//                            input  string pattern,
//                            output chandle h,
//                            output int     count );
//----------------------------------------------------------------

static void glob_freeFunc(saBuf_p p) {
  if (p==NULL) return;
  globfree((glob_t*)(p->data_ptr));
  free(p);
}

extern int SvLib_globStart(const char *pattern, void **h, int *number) {
  int result;
  saBuf_p sa;
  *number = 0;
  *h = NULL;
  result = saBufCreate(sizeof(glob_t), glob_freeFunc, &sa);
  if (result) {
    return result;
  }
  result = glob(pattern, GLOB_ERR | GLOB_MARK, NULL, sa->data_ptr);
  switch (result) {
    case GLOB_NOSPACE:
      glob_freeFunc(sa);
      return ENOMEM;
    case GLOB_ABORTED:
      glob_freeFunc(sa);
      return EACCES;
    case GLOB_NOMATCH:
    case 0:
      sa->scan = ((glob_t*)(sa->data_ptr))->gl_pathv;
      *number  = ((glob_t*)(sa->data_ptr))->gl_pathc;
      *h = (void*) sa;
      return 0;
    default:
      glob_freeFunc(sa);
      return ENOTSUP;
  }
}

typedef struct stat s_stat, *p_stat;

//----------------------------------------------------------------
//   import "DPI-C" function int SvLib_mtime(
//                            input  string path,
//                            output int    mtime);
//----------------------------------------------------------------

extern int SvLib_mtime(const char *path, int *mtime) {
  s_stat s;
  int e = stat(path, &s);
  if (e) {
    *mtime = 0;
    return e;
  } else {
    *mtime = s.st_mtime;
    return 0;
  }
}

extern int SvLib_dayTime() {
  time_t t = time(NULL);
  int ti = t;
  return ti;
}

#ifdef _CPLUSPLUS
}
#endif
