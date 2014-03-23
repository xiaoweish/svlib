//=============================================================================
//  @brief  types and classes for Config file processing
//  @author Jonathan Bromley, Verilab (www.verilab.com)
// =============================================================================
//
//                      svlib SystemVerilog Utilities Library
//
// @File: svlib_pkg_Cfg.svh
//
// Copyright 2014 Verilab, Inc.
// 
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
// 
//        http://www.apache.org/licenses/LICENSE-2.0
// 
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.
//=============================================================================


//=============================================================================
// Type definitions 

typedef enum {
  NODE_SCALAR, NODE_SEQUENCE, NODE_MAP,
  SCALAR_STRING, SCALAR_INT,
  FILE_INI, FILE_YAML
} cfgObjKind_enum;

typedef enum { // Codes for errors from this package

  // No error, must be zero for ease of return value testing
  CFG_OK = 0,

  // Errors caused by generic (de)serialize operations
  CFG_SERIALIZE_NULL,                // Called serialize(null)

  // Errors caused by YAML serialize/deserialize operations
  CFG_YAML_NOT_YET_IMPLEMENTED,

  // Errors caused by file (de)serialize operations
  CFG_DESERIALIZE_FILE_NOT_READ,     // cfgFile object isn't opened for read
  CFG_SERIALIZE_FILE_NOT_WRITE,      // cfgFile object isn't opened for write

  // Errors caused by INI (de)serialize operations
  CFG_DESERIALIZE_INI_BAD_SYNTAX,    // INI file contents are bad
  CFG_SERIALIZE_INI_TOP_NOT_MAP,     // Root node must be a map
  CFG_SERIALIZE_INI_SECTION_NOT_MAP, // Each element of root map must be a scalar or map
  CFG_SERIALIZE_INI_NOT_SCALAR,      // Each element of section map must be a scalar

  // Errors caused by addNode operations
  CFG_ADDNODE_CANNOT_ADD,    // called on an inappropriate node object
  CFG_ADDNODE_DUPLICATE_KEY, // map already has the new node's key
  CFG_ADDNODE_NULL,          // trying to add a null node

  // Errors caused by file I/O
  CFG_OPEN_NO_FILE,        // attempt to open a file that doesn't exist
  CFG_CLOSE_NO_FILE,       // attempt to close when object has no file open
  CFG_OPEN_BAD_FILE_MODE,  // attempt to open a file with bad mode

  // Errors caused by scalar value set/get operations
  CFG_LOOKUP_NOT_SCALAR,   // node is not a scalar

  // Errors caused by cfgNode::lookup operations
  CFG_LOOKUP_BAD_SYNTAX,   // lookup string badly formed
  CFG_LOOKUP_MISSING_DOT,  // expected nothing or dot after [N]
  CFG_LOOKUP_NOT_SEQUENCE, // attempted [N] lookup into non-sequence
  CFG_LOOKUP_NOT_MAP,      // attempted .key lookup into non-map
  CFG_LOOKUP_NULL_NODE,    // found a null node in the hierarchy
  CFG_LOOKUP_NOT_FOUND     // [N] out of range, or .key not found

} cfgError_enum;

// This enumeration actually represents a bit mask.
typedef enum int {
  CFG_OPT_NONE = 'h0000
} cfgOptions_enum;

//=============================================================================


//=============================================================================
// Abstract class definitions

virtual class svlibCfgBase extends svlibBase;
  //-----------------------------------------------------------------------------
  // Pure methods 

  pure virtual function cfgObjKind_enum kind();

  //-----------------------------------------------------------------------------
  // Protected functions and members

  protected string     name;
  protected cfgError_enum lastError;
  protected string     lastErrorDetails;
  protected virtual function void purge();
                      name = "";
                      lastError = CFG_OK;
                      lastErrorDetails = "";
                     endfunction: purge

  protected virtual function void cfgObjError(cfgError_enum err);
                      if (err == CFG_OK) return;
                      // There was an error. Set up the error information:
                      lastError = err;
                      lastErrorDetails = errorDetails(err);
                      // and throw the (optional) assertion error
                      cfgNode_check_validity : 
                        assert (err == CFG_OK) else
                          $error("%s \"%s\": %s",
                           kindStr(), name, lastErrorDetails);
                    endfunction: cfgObjError

  protected virtual function string errorDetails(cfgError_enum err);
                      return $sformatf("operation failed because %s", err.name);
                    endfunction: errorDetails

  //-----------------------------------------------------------------------------

  virtual function string     getName();             
    return name;             
  endfunction: getName

  virtual function string     getLastErrorDetails(); 
    return lastErrorDetails; 
  endfunction: getLastErrorDetails

  virtual function cfgError_enum getLastError();        
    return lastError;        
  endfunction: getLastError

  virtual function string kindStr();
    cfgObjKind_enum k = kind();
    return k.name;
  endfunction: kindStr

endclass: svlibCfgBase

virtual class cfgScalar extends svlibCfgBase;
  //-----------------------------------------------------------------------------
  // Pure methods 

  pure virtual function string       str();
  pure virtual function bit          scan(string s);

  //-----------------------------------------------------------------------------

endclass: cfgScalar

virtual class cfgNode extends svlibCfgBase;
  //-----------------------------------------------------------------------------
  // Pure methods 

  pure virtual function string       sformat(int indent = 0);
  pure virtual function cfgNode      childByName(string idx);

  //-----------------------------------------------------------------------------

  string comments[$];
  string serializationHint;

  //-----------------------------------------------------------------------------
  // Protected functions and members

  protected cfgNode          parent;
  protected cfgNode          foundNode;
  protected string           foundPath;
  protected virtual function void purge();
                      super.purge();
                      comments.delete();
                      serializationHint = "";
                      parent = null;
                    endfunction: purge

  //-----------------------------------------------------------------------------


  extern virtual function cfgNode lookup(string path);

  virtual function void addNode(cfgNode nd);
    cfgObjError(CFG_ADDNODE_CANNOT_ADD);
  endfunction: addNode

  virtual function cfgNode    getFoundNode(); 
    return foundNode;   
  endfunction: getFoundNode

  virtual function string     getFoundPath(); 
    return foundPath;   
  endfunction: getFoundPath

  virtual function cfgNode    getParent();    
    return parent;      
  endfunction: getParent
endclass: cfgNode

virtual class cfgSerDes extends svlibCfgBase;
  //-----------------------------------------------------------------------------
  // Pure methods 

  pure virtual function cfgError_enum serialize  (cfgNode node, int options=0);
  pure virtual function cfgNode    deserialize(int options=0);

  //-----------------------------------------------------------------------------
endclass: cfgSerDes

virtual class cfgFile extends cfgSerDes;
  //-----------------------------------------------------------------------------
  // Protected functions and members

  protected string filePath;
  protected int    fd;
  protected string mode;
  protected virtual function void purge();
    super.purge();
    if (fd) void'(close());
  endfunction: purge
  protected virtual function cfgError_enum open(string fp, string rw);
    void'(close());
    if (!(rw inside {"r", "w"})) begin
      return CFG_OPEN_BAD_FILE_MODE;
    end
    fd = $fopen(fp, rw);
    if (fd) begin
      filePath = fp;
      mode = rw;
    end
    return (mode != "") ? CFG_OK : CFG_OPEN_NO_FILE;
  endfunction: open

  //-----------------------------------------------------------------------------

  virtual function string getFilePath(); 
    return filePath;     
  endfunction: getFilePath

  virtual function string getMode();     
    return mode;         
  endfunction: getMode

  virtual function int    getFD();       
    return fd;           
  endfunction: getFD

  virtual function cfgError_enum openW(string fp); 
    return open(fp, "w"); 
  endfunction: openW

  virtual function cfgError_enum openR(string fp); 
    return open(fp, "r"); 
  endfunction: openR

  virtual function cfgError_enum close();
    mode = "";
    filePath = "";
    if (fd) begin
      $fclose(fd);
      fd = 0;
      return CFG_OK;
    end
    else begin
      return CFG_CLOSE_NO_FILE;
    end
  endfunction: close
endclass: cfgFile

//=============================================================================
// Concrete class definitions extended from cfgNode

class cfgNodeScalar extends cfgNode;
  cfgScalar value;

  //-----------------------------------------------------------------------------
  // Protected functions and members

  // protected constructor via macro
  `SVLIB_CFG_NODE_UTILS(cfgNodeScalar)
  protected virtual function void purge();
    super.purge();
    value = null;
  endfunction: purge

  //-----------------------------------------------------------------------------

  function string sformat(int indent = 0);
    return $sformatf("%s%s", str_repeat(" ", indent), value.str());
  endfunction: sformat


  function cfgObjKind_enum kind(); 
    return NODE_SCALAR; 
  endfunction: kind

  function cfgNode childByName(string idx); 
    return null; 
  endfunction: childByName
endclass: cfgNodeScalar

class cfgNodeSequence extends cfgNode;
  cfgNode value[$];

  //-----------------------------------------------------------------------------
  // Protected functions and members

  // protected constructor via macro
  `SVLIB_CFG_NODE_UTILS(cfgNodeSequence)

  protected virtual function void purge();
    super.purge();
    value.delete();
  endfunction: purge

  //-----------------------------------------------------------------------------

  function string sformat(int indent = 0);
    foreach (value[i]) begin
      if (i != 0) sformat = {sformat, "\n"};
      sformat = {sformat, str_repeat(" ", indent), "- \n", value[i].sformat(indent+1)};
    end
  endfunction: sformat

  function cfgObjKind_enum kind(); 
    return NODE_SEQUENCE; 
  endfunction: kind

  virtual function void addNode(cfgNode nd);
    if (nd == null) begin
      cfgObjError(CFG_ADDNODE_NULL);
      return;
    end
    nd.parent = this;
    value.push_back(nd);
    cfgObjError(CFG_OK);
  endfunction: addNode

  function cfgNode childByName(string idx);
    int n = idx.atoi();
    if (n >= value.size() || n<0)
      return null;
    else
      return value[n];
  endfunction: childByName
endclass: cfgNodeSequence

class cfgNodeMap extends cfgNode;
  //-----------------------------------------------------------------------------
  // Protected functions and members

  // protected constructor via macro

  `SVLIB_CFG_NODE_UTILS(cfgNodeMap)
  protected virtual function void purge();
    super.purge();
    value.delete();
  endfunction: purge

  //-----------------------------------------------------------------------------

  cfgNode value[string];

  function string sformat(int indent = 0);
    bit first = 1;
    foreach (value[s]) begin
      if (first)
        first = 0;
      else
        sformat = {sformat, "\n"};
      sformat = {sformat, str_repeat(" ", indent), s, " : \n", value[s].sformat(indent+1)};
    end
  endfunction: sformat

  function cfgObjKind_enum kind(); 
    return NODE_MAP; 
  endfunction: kind

  virtual function void addNode(cfgNode nd);
    if (nd == null) begin
      cfgObjError(CFG_ADDNODE_NULL);
      return;
    end
    if (value.exists(nd.getName())) begin
      cfgObjError(CFG_ADDNODE_DUPLICATE_KEY);
    end
    nd.parent = this;
    value[nd.getName()] = nd;
    cfgObjError(CFG_OK);
  endfunction: addNode

  function cfgNode childByName(string idx);
    if (!value.exists(idx))
      return null;
    else
      return value[idx];
  endfunction: childByName

endclass: cfgNodeMap

//=============================================================================
// Special abstract class definition

virtual class cfgTypedScalar #(type T = int) extends cfgScalar;
  T value;
  protected virtual function void purge();
    T tmp;  // initializes itself
    super.purge();
    value = tmp;
  endfunction: purge

  virtual function T    get();    
    return value; 
  endfunction: get

  virtual function void set(T v); 
    value = v;    
  endfunction: set
endclass: cfgTypedScalar

//=============================================================================
// Concrete class definitions extended from cfgTypedScalar

class cfgScalarInt extends cfgTypedScalar#(logic signed [63:0]);
  //-----------------------------------------------------------------------------
  // Protected functions and members

  // forbid construction
  protected function new(); 
            endfunction: new

  //-----------------------------------------------------------------------------

  function string str();
    if (!$isunknown(value)) begin
      return $sformatf("%0d", value);
    end
    else if (value < 0) begin
      // Has X/Z but is known to be -ve
      return $sformatf("-'h%0h", -value);
    end
    else begin
      // Has X/Z but is not -ve
      return $sformatf("'h%0h", value);
    end
  endfunction: str

  extern function bit scan(string s);

  function cfgObjKind_enum kind(); 
    return SCALAR_INT; 
  endfunction: kind

  static function cfgScalarInt create(T v = 0);
    create = Obstack#(cfgScalarInt)::obtain();
    create.name = "";
    create.value = v;
  endfunction: create 
  static function cfgNodeScalar createNode(string name, T v = 0);
    cfgNodeScalar ns = cfgNodeScalar::create(name);
    ns.value = cfgScalarInt::create(v);
    return ns;
  endfunction: createNode

endclass: cfgScalarInt

class cfgScalarString extends cfgTypedScalar#(string);
  //-----------------------------------------------------------------------------
  // Protected functions and members

  // forbid construction
  protected function new(); 
            endfunction: new

  //-----------------------------------------------------------------------------

  function string str();
    return get();
  endfunction:str

  function bit scan(string s);
    set(s);
    return 1;
  endfunction: scan

  function cfgObjKind_enum kind(); 
   return SCALAR_STRING; 
  endfunction: kind

  static function cfgScalarString create(string v = "");
    create = Obstack#(cfgScalarString)::obtain();
    create.name = "";
    create.value = v;
  endfunction: create

  static function cfgNodeScalar createNode(string name, string v = "");
    cfgNodeScalar ns = cfgNodeScalar::create(name);
    ns.value = cfgScalarString::create(v);
    return ns;
  endfunction: createNode

endclass: cfgScalarString

//=============================================================================
// Concrete class definitions extended from cfgFile

class cfgFileINI extends cfgFile;
  //-----------------------------------------------------------------------------
  // Protected functions and members

  // forbid construction
  protected function new(); 
            endfunction: new

  protected virtual function void writeComments(cfgNode node);
    if (node.comments.size() > 0) $fdisplay(fd);
    foreach (node.comments[i]) $fdisplay(fd, "# %s", node.comments[i]);
  endfunction: writeComments

  protected function cfgError_enum writeScalar(string key, cfgNodeScalar ns);
    cfgScalarString css;
    Str str;
    bit must_quote;
    writeComments(ns);
    // Special case: protect strings with quotes if they contain spaces.
    if ($cast(css, ns.value)) begin
      str = Obstack#(Str)::obtain();
      str.set(css.value);
      must_quote = (str.first(" ") >= 0);
      Obstack#(Str)::relinquish(str);
    end
    if (must_quote) begin
      $fdisplay(fd, "%s=%s", key, str_quote(ns.sformat()));
    end
    else begin
      $fdisplay(fd, "%s=%s", key, ns.sformat());
    end
    return CFG_OK;
  endfunction: writeScalar

  protected function cfgError_enum writeMap(string key, cfgNodeMap nm);
    cfgError_enum err;
    $fdisplay(fd);
    writeComments(nm);
    $fdisplay(fd, "[%s]", key);
    foreach (nm.value[k2]) begin
      cfgNode nd = nm.value[k2];
      if (nm.value[k2].kind() != NODE_SCALAR) begin
        return CFG_SERIALIZE_INI_NOT_SCALAR;
      end
      else begin
        cfgNodeScalar ns;
        $cast(ns, nm.value[k2]);
        err = writeScalar(k2, ns);
        if (err != CFG_OK) return err;
      end
    end
    return CFG_OK;
  endfunction: writeMap

  protected function void getRoot(ref cfgNodeMap it);
    if (it == null)
      it = cfgNodeMap::create("deserialized_INI_file");
  endfunction: getRoot

  //-----------------------------------------------------------------------------

  function cfgObjKind_enum kind(); 
    return FILE_INI; 
  endfunction: kind

  static function cfgFileINI create(string name = "INI_FILE");
    create = Obstack#(cfgFileINI)::obtain();
    create.name = name;
  endfunction: create

  function cfgError_enum serialize  (cfgNode node, int options=0);
    cfgNodeMap root;
    cfgError_enum err;
    if (mode != "w")             return CFG_SERIALIZE_FILE_NOT_WRITE;
    if (node == null)            return CFG_SERIALIZE_NULL;
    if (node.kind() != NODE_MAP) return CFG_SERIALIZE_INI_TOP_NOT_MAP;
    // It's a map. Traverse it...
    writeComments(node);
    $cast(root, node);
    // For .INI, must write out all the scalars first.
    foreach (root.value[key]) begin
      if (root.value[key].kind() == NODE_SCALAR) begin
        cfgNodeScalar ns;
        $cast(ns, root.value[key]);
        err = writeScalar(key, ns);
        if (err != CFG_OK) return err;
      end
    end
    // Then write out all the maps - one level deep only!  
    foreach (root.value[key]) begin
      case (root.value[key].kind())
        NODE_SCALAR: ; // we've done those already
        NODE_MAP:
          begin
            cfgNodeMap nm;
            $cast(nm, root.value[key]);
            err = writeMap(key, nm);
            if (err != CFG_OK) return err;
          end
        default:
          return CFG_SERIALIZE_INI_SECTION_NOT_MAP;
      endcase
    end
    $fdisplay(fd);
    return CFG_OK;
  endfunction: serialize


  function cfgNode deserialize(int options=0);

    cfgNodeMap      root;
    cfgNodeMap      section;
    cfgNodeScalar   keyVal;
    string          value;
    qs              comments;
    Regex           reComment;
    Regex           reSection;
    Regex           reKeyVal;
    Str             strLine;

    if (mode != "r") begin
      cfgObjError(CFG_DESERIALIZE_FILE_NOT_READ);
      return null;
    end

    reComment = Obstack#(Regex)::obtain();
    reSection = Obstack#(Regex)::obtain();
    reKeyVal  = Obstack#(Regex)::obtain();
    strLine   = Obstack#(Str)::obtain();

    reComment.setRE("^\\s*[;#]\\s?(.*)$");
    reSection.setRE("^\\s*\\[\\s*(\\w+)\\s*\\]$");
    reKeyVal.setRE("^\\s*(\\w+)\\s*[=:]\\s*((.*[^ '\"])|(['\"])(.*)\\4)\\s*$");

    `foreach_line(fd, line, linenum) begin

      strLine.set(line);
      strLine.trim(Str::RIGHT);
      if (strLine.len() == 0) continue;

      if (reComment.test(strLine)) begin
        comments.push_back(reComment.getMatchString(1));
      end
      else if (reSection.test(strLine)) begin
        section = cfgNodeMap::create(reSection.getMatchString(1));
        section.comments = comments;
        comments.delete();
        getRoot(root);
        root.addNode(section);
      end
      else if (reKeyVal.test(strLine)) begin
        if (reKeyVal.getMatchStart(3) >=0) begin
          value = reKeyVal.getMatchString(3);
        end
        else begin
          value = reKeyVal.getMatchString(5);
        end
        keyVal = cfgScalarString::createNode(reKeyVal.getMatchString(1), value);
        keyVal.comments = comments;
        comments.delete();
        if (section) begin
          section.addNode(keyVal);
        end
        else begin
          getRoot(root);
          root.addNode(keyVal);
        end
      end
      else begin
        lastError = CFG_DESERIALIZE_INI_BAD_SYNTAX;
        $display("bad syntax in line %0d \"%s\"", linenum, strLine.get());
      end

    end

    Obstack#(Regex)::relinquish(reComment);
    Obstack#(Regex)::relinquish(reSection);
    Obstack#(Regex)::relinquish(reKeyVal);
    Obstack#(Str)::relinquish(strLine);
    cfgObjError(lastError);
    return (lastError == CFG_OK) ? root : null;

  endfunction: deserialize

endclass: cfgFileINI

class cfgFileYAML extends cfgFile;
  //-----------------------------------------------------------------------------
  // Protected functions and members

  // forbid construction
  protected function new(); 
            endfunction: new

  protected function void purge();
    super.purge();
  endfunction: purge

  //-----------------------------------------------------------------------------

  function cfgObjKind_enum kind(); 
    return FILE_YAML; 
  endfunction: kind

  static function cfgFileYAML create(string name = "YAML_FILE");
    create = Obstack#(cfgFileYAML)::obtain();
    create.name = name;
  endfunction: create

  function cfgError_enum serialize  (cfgNode node, int options=0);
    return CFG_YAML_NOT_YET_IMPLEMENTED;
  endfunction: serialize

  function cfgNode deserialize(int options=0);
    cfgObjError(CFG_YAML_NOT_YET_IMPLEMENTED);
    return null;
  endfunction: deserialize

endclass: cfgFileYAML

// ============================================================================
/////////////////// IMPLEMENTATIONS OF EXTERN CLASS METHODS ///////////////////

`include "svlib_impl_Cfg.svh"
