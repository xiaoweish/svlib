`ifndef SVLIB_MACROS__DEFINED
`define SVLIB_MACROS__DEFINED

`define forenum(E,e,i=foreach_enum_position_iterator) \
  for (E e = e.first, int i=0; i<e.num; e=e.next, i++)
  
`endif
