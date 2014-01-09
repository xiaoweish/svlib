#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <glob.h>
#include <time.h>
#include <regex.h>

#include <veriuser.h>
#include <svdpi.h>

#include "../svlib_shared_c_sv.h"

#define STRINGIFY(x) MACROHASH(x)
#define MACROHASH(x) #x

#define SVLIB_STRING_BUFFER_START_SIZE       (256)
#define SVLIB_STRING_BUFFER_LONGEST_PATHNAME (8192)

#ifdef _CPLUSPLUS
extern "C" {
#endif

static char*  libStringBuffer = NULL;
static size_t libStringBufferSize = 0;

/*--------------------------------------------------------------------------
 * FOR INTERNAL USE BY SVLIB ONLY:
 *--------------------------------------------------------------------------
 * Get a new string buffer of given size.
 * If size<=0 and there is currently no buffer,
 * create one with the default size. If size=0 and
 * there is already a buffer, return it. If size<0
 * and there is already a buffer, double its existing
 * size and then return it.
 */ 
static char* getLibStringBuffer(size_t size) {
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
      /* Report the error and return the existing buffer, whatever it is */
      perror("PROBLEM in SvLib::getLibStringBuffer: cannot malloc");
    } else {
      free(libStringBuffer);
      libStringBuffer = buf;
      libStringBufferSize = size;
    }
  }
  return libStringBuffer;
}

static size_t getLibStringBufferSize() {
  if (libStringBuffer==NULL) {
    return 0;
  } else {
    return libStringBufferSize;
  }
}

/*--------------------------------------------------------------------------
 * FOR INTERNAL USE BY SVLIB ONLY:
 *--------------------------------------------------------------------------
 * Mechanism to retrieve an array of strings from C into SV.
 * A function such as 'glob' whose main result is an array of strings
 * will construct such an array in internal storage here, then return
 * a chandle pointing to the sa_buf_struct that records the array of strings
 * and the SvLib's progress through collecting them.
 * Subsequent calls to SvLib_saBufNext with this chandle will then
 * serve up the strings one by one, finally returning with the chandle set
 * to null to indicate that all the strings have been consumed and the 
 * C-side internal storage has been freed and is no longer accessible.
 */

/* Each different data source will require its own mem-free callback. */
typedef void (*freeFunc_decl)(saBuf_p);

typedef struct saBuf {
  char        ** scan;         /* pointer to the current array element */
  freeFunc_decl  freeFunc;     /* function to call on exhaustion       */
  void         * data_ptr;     /* pointer to app-specific data         */
  struct saBuf * sanity_check; /* pointer-to-self for checking         */
} saBuf_s, *saBuf_p;

static int32_t saBufCreate(size_t dataBytes, freeFunc_decl ff, saBuf_p *created) {
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

/*-------------------------------------------------------------------------------
 * import "DPI-C" function int SvLib_saBufNext(inout chandle h, output string s);
 *-------------------------------------------------------------------------------
 */
extern int32_t SvLib_saBufNext(void **h, const char **s) {
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

/*-------------------------------------------------------------------
 * import "DPI-C" function string SvLib_getCErrStr(input int errnum);
 *-------------------------------------------------------------------
 */
extern const char* SvLib_getCErrStr(int32_t errnum) {
  return strerror(errnum);
}

/*----------------------------------------------------------------
 * import "DPI-C" function int SvLib_getcwd(output string result);
 *----------------------------------------------------------------
 */
extern int32_t SvLib_getcwd(char ** p_result) {

  size_t  bSize = SVLIB_STRING_BUFFER_START_SIZE;
  char  * buf;

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

/*----------------------------------------------------------------
 * import "DPI-C" function int SvLib_timeFormat(
 *                                       input  longint epochTime, 
 *                                       input  string  format, 
 *                                       output string  formatted);
 *----------------------------------------------------------------
 */
extern int32_t SvLib_timeFormat(int64_t epochTime, const char *fs, const char ** p_result) {
  
  size_t  bSize = SVLIB_STRING_BUFFER_START_SIZE;
  char  * buf;
  time_t t = epochTime;  /* to keep C library time functions happy */
  
  /* There is no way to determine string overfill error unless we 
   * can guarantee the result string is non-empty. So we prefix
   * the result string with a space to ensure non-emptiness. Ugh.
   */
  char * fss = malloc(strlen(fs)+2);
  *fss = ' ';
  strcpy(&(fss[1]), fs);  

  while (1) {
    buf   = getLibStringBuffer(bSize);
    bSize = getLibStringBufferSize();
    if (0 != strftime(buf, bSize, fss, localtime(&t))) {
      *p_result = &(buf[1]); /* skip added space */
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

/*----------------------------------------------------------------
 *   import "DPI-C" function int SvLib_globStart(
 *                            input  string pattern,
 *                            output chandle h,
 *                            output int     count );
 *----------------------------------------------------------------
 */
static void glob_freeFunc(saBuf_p p) {
  if (p==NULL) return;
  globfree((glob_t*)(p->data_ptr));
  free(p);
}

extern int32_t SvLib_globStart(const char *pattern, void **h, uint32_t *number) {
  int32_t result;
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
      *number  = 0;
      *h       = NULL;
      glob_freeFunc(sa);
      return 0;
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

/*----------------------------------------------------------------
 *   import "DPI-C" function int SvLib_fileStat(
 *                            input  string  path,
 *                            input  int     asLink,
 *                            output longint stats[statARRAYSIZE]);
 *----------------------------------------------------------------
 */
extern int32_t SvLib_fileStat(const char *path, int asLink, int64_t *stats) {
  s_stat s;
  uint32_t e;
  if (asLink) {
    /* if *path is a symlink, don't follow the link but stat it */
    e = lstat(path, &s);
  } else {
    /* normal stat, follow symlink */
    e = stat(path, &s);
 }
  if (e) {
    return errno;
  } else {
    stats[statMTIME] = s.st_mtime;
    stats[statATIME] = s.st_atime;
    stats[statCTIME] = s.st_ctime;
    stats[statSIZE]  = s.st_size;
    stats[statMODE]  = s.st_mode;
    return 0;
  }
}

/*----------------------------------------------------------------
 *   import "DPI-C" function int SvLib_dayTime();
 *----------------------------------------------------------------
 */
extern int64_t SvLib_dayTime() {
  return time(NULL);
}

/*----------------------------------------------------------------
 *  import "DPI-C" function string SvLib_regexErrorString(input int err, input string re);
 *----------------------------------------------------------------
 */
extern const char* SvLib_regexErrorString(int32_t err, const char* re) {
  uint32_t actSize, bSize;
  regex_t  compiled;
  char* buf;
  err = regcomp(&compiled, re, REG_EXTENDED);
  if (!err) {
    buf = NULL;
  } else {
    /* First, try to get result into existing buffer first. */
    actSize = 0;
    do {
      buf = getLibStringBuffer(actSize);
      bSize = getLibStringBufferSize();
      actSize = regerror(err, &compiled, buf, bSize);
      /* But resize buffer to fit if required. */
    } while (actSize > bSize);
  }
  regfree(&compiled);
  return buf;
/*
  switch (err) {
    case REG_BADBR : return
              "Invalid use of back reference operator";
    case REG_BADPAT : return
              "Invalid use of pattern operators such as group or list";
    case REG_BADRPT : return
              "Invalid use of repetition operators";
    case REG_EBRACE : return
              "Un-matched brace interval operators";
    case REG_EBRACK : return
              "Un-matched bracket list operators";
    case REG_ECOLLATE : return
              "Invalid collating element";
    case REG_ECTYPE : return
              "Unknown character class name";
    case REG_EEND : return
              "Non-specific error, not defined by POSIX.2";
    case REG_EESCAPE : return
              "Trailing backslash";
    case REG_EPAREN : return
              "Un-matched parenthesis group operators";
    case REG_ERANGE : return
              "Invalid use of the range operator";
    case REG_ESIZE : return
              "Compiled RE requires a pattern buffer larger than 64Kb";
    case REG_ESPACE : return
              "The regex routines ran out of memory";
    case REG_ESUBREG : return
              "Invalid back reference to a subexpression";
  }
  return "Unknown regular expression error";
*/
}

/*----------------------------------------------------------------
 *   import "DPI-C" function int SvLib_regexRun(
 *                            input  string re,
 *                            input  string str,
 *                            input  int    options,
 *                            input  int    startPos,
 *                            output int    matchCount,
 *                            output int    matchList[]);
 *----------------------------------------------------------------
*/
extern uint32_t SvLib_regexRun(
    const char *re,
    const char *str,
    int32_t     options,
    int32_t     startPos,
    int32_t    *matchCount,
    svOpenArrayHandle matchList
  ) {
  uint32_t result;
  regex_t    compiled;
  regmatch_t * matches;
  uint32_t numMatches;
  uint32_t i;
  uint32_t cflags;
  
  /* initialize result */
  *matchCount = 0;
  
  /* result array checks */
  if (svDimensions(matchList) != 1) {
    io_printf("svDimensions=%d, should be 1\n", svDimensions(matchList));
    return -1;
  }
  numMatches = svSizeOfArray(matchList) / sizeof(uint32_t);
  if (numMatches != 0) {
    if ((numMatches % 2) != 0) {
      io_printf("Odd number of elements in matchList\n");
      return -1;
    }
    numMatches /= 2;
    /* We are obliged to assume that the array has ascending range
     * because IUS doesn't yet support svIncrement. In practice this
     * is not a problem because the open array is always supplied
     * by a calling routine that is fully under the library's control.
     * if (svIncrement(matchList,1)>0) {
     *   io_printf("Descending subscripts in array!\n");
     *   return -1;
     * }
     */
    if (svLeft(matchList, 1) != 0) {
      io_printf("svLeft=%d, should be 0\n", svLeft(matchList,1));
      return -1;
    }
    matches = malloc(numMatches * sizeof(regmatch_t));
  }
  
  cflags = REG_EXTENDED;
  if (options & 1) cflags |= REG_ICASE;
  if (options & 2) cflags |= REG_NEWLINE;
  result = regcomp(&compiled, re, cflags);
  if (result) {
    regfree(&compiled);
    return result;
  }
  
  *matchCount = compiled.re_nsub+1;
  result = regexec(&compiled, &(str[startPos]), numMatches, matches, 0);
  if (result == 0) {
    /* successful match: copy matches into SV from struct[] */
    for (i=0; i<numMatches && i<*matchCount; i++) {
      *(regoff_t*)(svGetArrElemPtr1(matchList, 2*i  )) = matches[i].rm_so + startPos;
      *(regoff_t*)(svGetArrElemPtr1(matchList, 2*i+1)) = matches[i].rm_eo + startPos;
    }
  } else if (result == REG_NOMATCH) {
    /* no match, that's OK, we return matchCount==0 */
    result = 0;
    *matchCount = 0;
  }
  regfree(&compiled);
  if (numMatches) free(matches);
  return result;
}

#ifdef _CPLUSPLUS
}
#endif
