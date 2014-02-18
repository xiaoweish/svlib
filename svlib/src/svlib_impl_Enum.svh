//=============================================================================
//  @brief  Implementations (bodies) of extern functions in class Enum
//  @author Jonathan Bromley, Verilab (www.verilab.com)
// =============================================================================
//
//                      svlib SystemVerilab Utilities Library
//
// @File: svlib_impl_Enum.svh
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
// svlib_Enum_impl.sv
// ------------------
// Implementations (bodies) of extern functions in class Enum
//
// This file is `include-d into svlib_Enum_pkg.sv and
// should not be used in any other context.

function void EnumUtils::m_build();
  ENUM e = e.first;
  for (int pos=0; pos<e.num; pos++) begin
    m_all_values.push_back(e);
    m_map[e.name] = e;
    m_pos[e] = pos;
    e = e.next;
  end
  m_built = 1;
endfunction

function EnumUtils::qe EnumUtils::all_values();
  if (!m_built) m_build();
  return m_all_values;
endfunction

function bit EnumUtils::has_name(string s);
  if (!m_built) m_build();
  return m_map.exists(s);
endfunction

function bit EnumUtils::has_value(EnumUtils::BASE b);
  if (!m_built) m_build();
  return m_pos.exists(b);
endfunction

function EnumUtils::ENUM EnumUtils::from_name(string s);
  ENUM result; // default init value
  if (!m_built) m_build();
  if (has_name(s))
    result = m_map[s];
  return result;
endfunction

function int EnumUtils::pos(BASE b);
  if (has_value(b))
    return m_pos[b];
  else
    return -1;
endfunction

function EnumUtils::ENUM EnumUtils::match(EnumUtils::BASE b, bit requireUnique = 0);
  qe matchList;
  if (!m_built) m_build();
  matchList = m_all_values.find() with(b ==? item);
  if (matchList.size()==1 || (matchList.size()>1 && !requireUnique))
    return matchList[0];
  assert (0) else $error("EnumUtils::match found no match for value 'b%b", b);
  return ENUM'(b);
endfunction


