/*
-- (c) Copyright 2019 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES. 
--------------------------------------------------------------------------------
--
-- Vendor         : Xilinx
-- Revision       : $Revision: #1 $
-- Date           : $DateTime: 2023/01/18 10:56:50 $
-- Last Author    : $Author: xbuild $
--
--------------------------------------------------------------------------------
-- Description : Minimal example of a user extern behavioural model
--
--------------------------------------------------------------------------------
*/

#include <bm/bm_sim/actions.h>
#include <bm/bm_sim/extern.h>
#include <bm/bm_sim/logger.h>

template <typename... Args>
using ActionPrimitive = bm::ActionPrimitive<Args...>;
using bm::ExternType;

// Refer to the definitions of these classes in the header files included with
// this source file to understand the operations that can be performed on their
// instances.  Briefly:
// - Data
//      - Represents a general bit vector
//      - Contains several methods for arithmetic operations
// - Field
//      - Represents a named bit vector (i.e. a variable in a P4 program)
//      - Inherits from the Data class and supports all of its methods
// - Header
//      - Represents structured data
//      - Container class for one or more instances of Field
using bm::Data;
using bm::Field;
using bm::Header;

// Below is a minimal example of user extern behavioral model.  In this case,
// the model simply performs a data round-trip - the data value stored on the
// input parameter is propagated to the output parameter.
//
// Important features of the definition are:
// - Class name
//      - The name of the class here must match the name of the extern instance
//      used in the P4 program (refer to user_externs.p4)
// - Class setup
//      - All user extern models must inherit from ExternType
//      - The public section must contain BM_EXTERN_ATTRIBUTES {} to properly
//      contstruct the class
// - apply()
//      - The apply() method is where the extern modelling code belongs
//      - It is critical that the types of the parameters of the apply() method
//      are compatible with the parameters that are passed in to the method when
//      it is invoked in the P4 program.  The rules are:
//          -   P4 progam passes a constant: Use Data
//          -   P4 progam passes a variable: Use Field
//          -   P4 progam passes a structure: Use Header
//      Failure to correctly match the data types will result in an assertion
//      when the execution of the behavioural model reaches the user extern
//  - Class registration
//      -   The BM_REGISTER_EXTERN() macro installs the extern class definition
//      -   The BM_REGISTER_EXTERN_METHOD() macro installs the apply() method
//      -   In particular, it is critical to ensure that the parameters of this
//      macro agree with the parameters of the apply() method.  Failure to
//      correctly match the data types will result compilation error
class minimal_user_extern_example : public ExternType {
 public:
  BM_EXTERN_ATTRIBUTES {}
  // Update parameter data types in accordance with the guidance above.  First
  // parameter is the input and should always be declared as const accordingly
  void apply(const Field& in, Field& out) {
    BMLOG_DEBUG("minimal_user_extern_example: input data = {}", in);
    out.set(in);
    BMLOG_DEBUG("minimal_user_extern_example: output data = {}", out);
  }
};

// Update the parameters to both macros to match any and all changes made to the
// class definition above i.e. class name and apply() method parameter types
BM_REGISTER_EXTERN(minimal_user_extern_example);
BM_REGISTER_EXTERN_METHOD(minimal_user_extern_example, apply, const Field&, Field&);

////////////////////////////////////////////////////////////////////////////////

// In addition to the above minimal example, source for the externs used with
// the calulator_extended.p4 example design is provided below.  These are more
// realistic examples of user extern modelling.  Users who wish to run the
// calculator_extended.p4 program through the behavioural model will need to
// use the load-modules option to specify a shared object containing the code
// below.

// For sqrt()
#include <cmath>

class calc_divide : public ExternType {
 public:
  BM_EXTERN_ATTRIBUTES {}
  void apply(const Header& in, Header& out) {
    BMLOG_DEBUG("calc_divide: input header {}", in.get_name());
    const Field& divisor = in.get_field(0);
    const Field& dividend = in.get_field(1);
    BMLOG_DEBUG("calc_divide: divisor = {}", divisor);
    BMLOG_DEBUG("calc_divide: dividend = {}", dividend);
    Field& remainder = out.get_field(0);
    Field& quotient = out.get_field(1);
    quotient.divide(dividend, divisor);
    remainder.mod(dividend, divisor);
    BMLOG_DEBUG("calc_divide: output header {}", out.get_name());
    BMLOG_DEBUG("calc_divide: remainder = {}", remainder);
    BMLOG_DEBUG("calc_divide: quotient = {}", quotient);
  }
};

BM_REGISTER_EXTERN(calc_divide);
BM_REGISTER_EXTERN_METHOD(calc_divide, apply, const Header&, Header&);

////////////////////////////////////////////////////////////////////////////////

class calc_square_root : public ExternType {
 public:
  BM_EXTERN_ATTRIBUTES {}
  void apply(const Data& in, Data& out) {
    BMLOG_DEBUG("calc_square_root: input data {}", in);
    auto input = in.get_uint();
    auto calc = static_cast<unsigned int>(std::sqrt(static_cast<double>(input)));
    out.set<unsigned int>(calc);
    BMLOG_DEBUG("calc_square_root: output data {}", out);
  }
};

BM_REGISTER_EXTERN(calc_square_root);
BM_REGISTER_EXTERN_METHOD(calc_square_root, apply, const Data&, Data&);
