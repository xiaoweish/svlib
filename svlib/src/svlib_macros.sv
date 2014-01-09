`ifndef SVLIB_MACROS__DEFINED
`define SVLIB_MACROS__DEFINED

`define forenum(E,e,i=foreach_enum_position_iterator) \
  for (E e = e.first, int i=0; i<e.num; e=e.next, i++)
  
`define SVLIB_CLASS_UTILS(T)                    \
  protected static function T randstable_new(); \
    `ifdef SVLIB_NO_RANDSTABLE_NEW              \
    T result = new();                           \
    `else                                       \
    std::process p = std::process::self();      \
    string randstate = p.get_randstate();       \
    T result = new();                           \
    p.set_randstate(randstate);                 \
    `endif                                      \
    return result;                              \
  endfunction
  
`define foreach_line(fid,line,linenum,start=1) \
  for ( int linenum=start, string line="";     \
        $fgets(line, fid) > 0;                 \
        linenum++                              \
      )

`endif
