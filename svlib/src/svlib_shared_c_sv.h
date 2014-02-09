/*  These enum typedefs are valid syntax in both C and SV,
 *  so this file can be #included into C code or `included into SV.
 *  The types are used to share constants specifying mapping between
 *  fields of some C struct and elements of an SV array.
 */

/*  STAT_INDEX_E
 *  Represents the stat struct returned by the fileStat DPI call.
 */
typedef enum {
  statMTIME,
  statATIME,
  statCTIME,
  statSIZE,
  statMODE,
  statARRAYSIZE /* must always be the last one */
} STAT_INDEX_E;

/*  TM_INDEX_E
 *  Represents the broken-down time struct used by 
 *  localtime() and related functions
 */
typedef enum {
  tmSEC,      /* seconds              */
  tmMIN,      /* minutes              */
  tmHOUR,     /* hours                */
  tmMDAY,     /* day of the month     */
  tmMON,      /* month                */
  tmYEAR,     /* year                 */
  tmWDAY,     /* day of the week      */
  tmYDAY,     /* day in the year      */
  tmISDST,    /* daylight saving time */
  tmISLY,     /* is it a leap year    */
  tmARRAYSIZE /* must always be the last one */
} TM_INDEX_E;

/*  REGEX_OPTIONS_E
 *  Represents the various options that can be set on a regex.
 *  The values of this enum are a bitmap, so that multiple
 *  options can be encoded by ORing together the values.
 */
typedef enum {
  regexNOCASE  = 1,
  regexNOLINE  = 2
} REGEX_OPTIONS_E;
