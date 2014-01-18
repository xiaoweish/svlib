`ifndef SVLIB_MACROS__DEFINED
`define SVLIB_MACROS__DEFINED

`define forenum(E,e,i=foreach_enum_position_iterator) \
  for (E e = e.first, int i=0; i<e.num; e=e.next, i++)

`define foreach_line(fid,line,linenum,start=1) \
  for ( int linenum=start, string line="";     \
        $fgets(line, fid) > 0;                 \
        linenum++                              \
      )

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

`define SVLIB_CFG_NODE_UTILS(T)               \
  `SVLIB_CLASS_UTILS(T)                       \
  static function T create(string name = ""); \
    T me = T::randstable_new();               \
    me.name = name;                           \
    me.parent = null;                         \
    return me;                                \
  endfunction

`define SVLIB_DOM_UTILS_BEGIN(T)                          \
  function void fromDOM(cfgNodeMap dom);                  \
    if (dom != null)                                      \
      __svlib_dom_superfunction__(1, "", dom);            \
  endfunction                                             \
  function cfgNodeMap toDOM(string name);                 \
    cfgNodeMap dom;                                       \
    __svlib_dom_superfunction__(0, name, dom);            \
    return dom;                                           \
  endfunction                                             \
  protected function void __svlib_dom_superfunction__(    \
      int purpose, string name, inout cfgNodeMap dom      \
    );                                                    \
    case (purpose)                                        \
    0 : // toDOM(name);                                   \
      begin                                               \
        if (dom == null) dom = cfgNodeMap::create(name);  \
      end                                                 \
    1 : // fromDOM(cfgNodeMap dom);                       \
      begin                                               \
        if (dom == null) return;                          \
      end                                                 \
    endcase

`define SVLIB_DOM_FIELD_OBJECT(MEMBER)                    \
  case (purpose)                                          \
  0 : // toDOM(name);                                     \
    begin                                                 \
      dom.addNode(MEMBER.toDOM(`"MEMBER`"));              \
    end                                                   \
  1 : // fromDOM(cfgNodeMap dom);                         \
    begin                                                 \
      cfgNodeMap nd;                                      \
      if ($cast(nd, dom.lookup(`"MEMBER`"))) begin        \
        if (nd != null) begin                             \
          if (MEMBER == null) MEMBER = new;               \
          MEMBER.fromDOM(nd);                             \
        end                                               \
      end                                                 \
    end                                                   \
  endcase


`define SVLIB_DOM_FIELD_STRING(MEMBER)                          \
  case (purpose)                                                \
  0 : // toDOM(name);                                           \
    begin                                                       \
      dom.addNode(cfgScalarString::createNode(`"MEMBER`", MEMBER)); \
    end                                                         \
  1 : // fromDOM(cfgNodeMap dom);                               \
    begin                                                       \
      cfgNodeScalar   MEMBER``__n;                              \
      cfgScalarString MEMBER``__s;                              \
      if ($cast(MEMBER``__n, dom.childByName(`"MEMBER`")))      \
        if (MEMBER``__n != null)                                \
          if ($cast(MEMBER``__s, MEMBER``__n.value))            \
            MEMBER = MEMBER``__s.get();                         \
    end                                                         \
  endcase

`define SVLIB_DOM_FIELD_INT(MEMBER)                             \
  case (purpose)                                                \
  0 : // toDOM(name);                                           \
    begin                                                       \
      dom.addNode(cfgScalarInt::createNode(                     \
                                  `"MEMBER`", MEMBER));         \
    end                                                         \
  1 : // fromDOM(cfgNodeMap dom);                               \
    begin                                                       \
      cfgNodeScalar MEMBER``__n;                                \
      cfgScalarInt  MEMBER``__s;                                \
      if ($cast(MEMBER``__n, dom.childByName(`"MEMBER`")))      \
        if (MEMBER``__n != null)                                \
          if ($cast(MEMBER``__s, MEMBER``__n.value))            \
            MEMBER = MEMBER``__s.get();                         \
    end                                                         \
  endcase

`define SVLIB_DOM_UTILS_END \
  endfunction

`endif
