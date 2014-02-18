//=============================================================================
//  @brief  Class to provide utility services for an enum.
//  @author Jonathan Bromley, Verilab (www.verilab.com)
// =============================================================================
//
//                      svlib SystemVerilab Utilities Library
//
// @File: svlib_pkg_Enum.svh
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
// Class to provide utility services for an enum.
// The type parameter MUST be overridden with an appropriate enum type.
// Leaving it at the default 'int' will give tons of elaboration-time errors.
// Nice polite 1800-2012-compliant tools should allow me to provide no default
// at all on the type parameter, enforcing the requirement for an override;
// but certain tools that shall remain nameless don't yet support that.
//

//=============================================================================
// class definitions

class EnumUtils #(type ENUM = int);

  typedef ENUM qe[$];
  typedef logic [$bits(ENUM)-1:0] BASE;

  //-----------------------------------------------------------------------------
  // Protected functions and members
  
  // List of all values, lazy-evaluated
  protected static qe   m_all_values;
  protected static ENUM m_map[string];
  protected static int  m_pos[BASE];
  protected static bit  m_built;
  // The lazy-evaluator
  extern protected static function void m_build();

  // forbid construction
  protected function new(); 
            endfunction: new

  extern static function ENUM from_name  (string s);
  extern static function int  pos        (BASE   b);
  extern static function bit  has_name   (string s);
  extern static function bit  has_value  (BASE   b);
  extern static function qe   all_values ();
  extern static function ENUM match      (BASE   b, bit requireUnique = 0);

endclass: EnumUtils

// ============================================================================
/////////////////// IMPLEMENTATIONS OF EXTERN CLASS METHODS ///////////////////

`include "svlib_impl_Enum.svh"
