//
// ext_fcn.cpp
//
#include <bm/bm_sim/actions.h>
#include <bm/bm_sim/extern.h>
#include <bm/bm_sim/logger.h>

template <typename... Args>
using ActionPrimitive = bm::ActionPrimitive<Args...>;
using bm::ExternType;

using bm::Data;
using bm::Field;
using bm::Header;

//
// ext_fcn simulates an extern block in P4 behavior models.
// It pipelines the data and sends it back to the P4 processing core (NOP).
//
class ext_fcn : public ExternType {

public:
  BM_EXTERN_ATTRIBUTES {}

  // apply simulates the invocation of the block
  void apply(const Header &in, Header &out) {

    // Get the field data structures for both the inputs and outputs.
    const Field &in_data = in.get_field(0); // 3
    Field &out_data = out.get_field(0); // 3

    // Populate fields
    out_data.set(in_data);
  }

};

BM_REGISTER_EXTERN(ext_fcn);
BM_REGISTER_EXTERN_METHOD(ext_fcn, apply, const Header &, Header &);


