#ifndef BM_BM_SIM_INTCHECKSUMIF_H_
#define BM_BM_SIM_INTCHECKSUMIF_H_
#include <memory>
#include <string>

enum class MethodType {
  METHOD_NONE,
  METHOD_CLEAR,
  METHOD_ADD,
  METHOD_SUBTRACT,
  METHOD_GET,
};

class InternetChecksumInterface {
public:
  virtual void set_calculation(MethodType type, std::string& instance_name)
  {
      //printf("set_calculation name %s type %d\n", instance_name.c_str(), (int)type);
      this->type = type;
      if((type == MethodType::METHOD_ADD) || (type == MethodType::METHOD_SUBTRACT))
        this->instance_name = instance_name;
  }
//private:
  //uint64_t internet_checksum{0};
  MethodType type{};
  std::string instance_name{};
};
#endif
