/*
 *  This enum typedef, which is valid syntax in both C and SV,
 *  is used to share constants specifying which 'stat' field 
 *  is represented in which element of the array passed back
 *  by the fileStat DPI call.
 */
typedef enum {
  statMTIME,
  statATIME,
  statCTIME,
  statSIZE,
  statMODE,
  statARRAYSIZE /* must always be the last one */
} STAT_INDEX_E;
