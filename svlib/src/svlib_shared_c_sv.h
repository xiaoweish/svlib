/*  These enum typedefs are valid syntax in both C and SV.
 *  They are used to share constants specifying mapping between
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
