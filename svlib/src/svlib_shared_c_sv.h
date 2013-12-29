/*
 *  This enum typedef, which is valid syntax in both C and SV,
 *  is used to share constants specifying which 'stat' field 
 *  will be extracted by any given function call.
 */
typedef enum {
  statMTIME = 1,
  statATIME = 2,
  statCTIME = 3,
  statSIZE  = 4,
  statMODE  = 5
} STAT_E;
