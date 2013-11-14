#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <glob.h>

#include <veriuser.h>
#include <svdpi.h>

#define STRINGIFY(x) MACROHASH(x)
#define MACROHASH(x) #x

#define SVLIB_STRING_BUFFER_START_SIZE       (1024)
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

typedef struct stat s_stat, *p_stat;


//----------------------------------------------------------------
//   import "DPI-C" function int SvLib_globStart(
//                            input  string pattern,
//                            output chandle hnd );
//   import "DPI-C" function int SvLib_globNext(
//                            input  chandle hnd,
//                            output int     count,
//                            output string  path );
//----------------------------------------------------------------

typedef struct gbuf_struct {
  struct gbuf_struct * sanity_check;
  char   **scan;
  glob_t *gb;
} gbuf_s, *gbuf_p;

static void gbuf_free(gbuf_p p) {
  if (p==NULL) return;
  globfree(p->gb);
  free(p);
}

extern int SvLib_globStart(const char *pattern, void **hnd) {
  int result;
  gbuf_p gbuf = malloc(sizeof(gbuf_s));
  *hnd = NULL;
  if (gbuf == NULL) {
    return ENOMEM;
  }
  gbuf->sanity_check = gbuf;
  gbuf->gb   = malloc(sizeof(glob_t));
  if (gbuf->gb == NULL) {
    free(gbuf);
    return ENOMEM;
  }
  result = glob(pattern, GLOB_ERR | GLOB_MARK, NULL, gbuf->gb);
  switch (result) {
    case GLOB_NOSPACE:
      gbuf_free(gbuf);
      return ENOMEM;
    case GLOB_ABORTED:
      gbuf_free(gbuf);
      return EACCES;
    case GLOB_NOMATCH:
    case 0:
      gbuf->scan = gbuf->gb->gl_pathv;
      *hnd = (void*) gbuf;
      return 0;
    default:
      gbuf_free(gbuf);
      return ENOTSUP;
  }
}

extern int SvLib_globNext(void *hnd, int *number, const char **path) {
  *number = 0;
  *path = NULL;
  if (hnd == NULL) {
    return 0;
  }
  gbuf_p p = (gbuf_p)hnd;
  if (p->sanity_check != p) {
    return ENOMEM;
  }
  if (p->scan != NULL) {
    *path = *(p->scan);
    *number = p->gb->gl_pathc - (p->scan - p->gb->gl_pathv);
    p->scan++;
  }
  if (*path == NULL) {
    gbuf_free(p);
  }
  return 0;
}

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

#ifdef _CPLUSPLUS
}
#endif
