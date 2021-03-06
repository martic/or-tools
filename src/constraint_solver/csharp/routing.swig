// Copyright 2010-2014 Google
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// TODO(user): Refactor this file to adhere to the SWIG style guide.

%include "constraint_solver/csharp/constraint_solver.swig"

// Include the file we want to wrap a first time.
%{
#include "constraint_solver/routing.h"
%}

%module(directors="1") operations_research;

// Convert RoutingModel::NodeIndex to (32-bit signed) integers.
%typemap(ctype) operations_research::RoutingModel::NodeIndex "int"
%typemap(imtype) operations_research::RoutingModel::NodeIndex "int"
%typemap(cstype) operations_research::RoutingModel::NodeIndex "int"
%typemap(csin) operations_research::RoutingModel::NodeIndex "$csinput"
%typemap(csout) operations_research::RoutingModel::NodeIndex {
  return $imcall;
}
%typemap(in) operations_research::RoutingModel::NodeIndex {
  $1 = operations_research::RoutingModel::NodeIndex($input);
}
%typemap(out) operations_research::RoutingModel::NodeIndex {
  $result = $1.value();
}
%typemap(csvarin) operations_research::RoutingModel::NodeIndex
%{
        set { $imcall; }
%}
%typemap(csvarout, excode=SWIGEXCODE)  operations_research::RoutingModel::NodeIndex
%{
  get {
        return $imcall;
  }
%}

// This typemap maps C# TypeA[] arrays to C++ std::vector<TypeB>, where
// TypeA and TypeB are strictly equivalent, bit-wise (like an IntType
// and an int, for example). This is done via an intermediate mapping
// to pairs (int length, TypeA*).
//
// We need to redefine it ourselves it because std_vector.i will only
// allow these conversions when TypeA == TypeB.
%define CS_TYPEMAP_STDVECTOR(TYPE, CTYPE, CSHARPTYPE)
%typemap(ctype)    const std::vector<TYPE>&  %{ int length$argnum, CTYPE* %}
%typemap(imtype)   const std::vector<TYPE>&  %{ int length$argnum, CSHARPTYPE[] %}
%typemap(cstype)   const std::vector<TYPE>&  %{ CSHARPTYPE[] %}
%typemap(csin)     const std::vector<TYPE>&  "$csinput.Length, $csinput"
%typemap(freearg)  const std::vector<TYPE>&  { delete $1; }
%typemap(in)       const std::vector<TYPE>&  %{
  $1 = new std::vector<TYPE>;
  $1->reserve(length$argnum);
  for(int i = 0; i < length$argnum; ++i) {
    $1->emplace_back($input[i]);
  }
%}
%enddef // CS_TYPEMAP_STDVECTOR

CS_TYPEMAP_STDVECTOR(operations_research::RoutingModel::NodeIndex, int, int);

// Ditto, for bi-dimensional arrays: map C# TypeA[][] to C++
// std::vector<std::vector<TypeB>>.
%define CS_TYPEMAP_STDVECTOR_IN1(TYPE, CTYPE, CSHARPTYPE)
%typemap(ctype)  const std::vector<std::vector<TYPE> >&  %{
  int len$argnum_1, int len$argnum_2, CTYPE*
%}
%typemap(imtype) const std::vector<std::vector<TYPE> >&  %{
  int len$argnum_1, int len$argnum_2, CSHARPTYPE[]
%}
%typemap(cstype) const std::vector<std::vector<TYPE> >&  %{ CSHARPTYPE[,] %}
%typemap(csin)   const std::vector<std::vector<TYPE> >&  "$csinput.GetLength(0),$csinput.GetLength(1), NestedArrayHelper.GetFlatArray($csinput)"
%typemap(in)     const std::vector<std::vector<TYPE> >&  (std::vector<std::vector<TYPE> > result) %{
  const int size_x = len$argnum_1;
  const int size_y = len$argnum_2;

  result.clear();
  result.resize(size_x);

  TYPE* inner_array = reinterpret_cast<TYPE*>($input);

  for (int index1 = 0; index1 < size_x; ++index1) {
    result[index1].reserve(size_y);
    for (int index2 = 0; index2 < size_y; ++index2) {
      const TYPE value = inner_array[index1 * size_y + index2];
      result[index1].emplace_back(value);
    }
  }

  $1 = &result;
%}
%enddef // CS_TYPEMAP_STDVECTOR_IN1

CS_TYPEMAP_STDVECTOR_IN1(operations_research::RoutingModel::NodeIndex, int, int);

// Create input mapping for NodeEvaluator2
%feature("director") NodeEvaluator2;
%{
class NodeEvaluator2 : private operations_research::RoutingModel::NodeEvaluator2 {
 public:
  NodeEvaluator2() : used_as_permanent_handler_(false) {}

  virtual ~NodeEvaluator2() {}

  virtual int64 Run(int i, int j) = 0;

  operations_research::RoutingModel::NodeEvaluator2* GetPermanentCallback() {
    CHECK(!used_as_permanent_handler_);
    used_as_permanent_handler_ = true;
    return this;
  }

 private:
  virtual bool IsRepeatable() const { return true; }

  virtual int64 Run(operations_research::RoutingModel::NodeIndex i,
                    operations_research::RoutingModel::NodeIndex j) {
    return Run(i.value(), j.value());
  }

  bool used_as_permanent_handler_;
};
%}

// We prefer keeping this C# extension here (instead of moving it to a dedicated
// C# file, using partial classes) because it uses SWIG's $descriptor().
%typemap(cscode) NodeEvaluator2 %{
  public $descriptor(operations_research::RoutingModel::NodeEvaluator2*) DisownAndGetPermanentCallback() {
    swigCMemOwn = false;
    return GetPermanentCallback();
  }
%}

class NodeEvaluator2 : private operations_research::RoutingModel::NodeEvaluator2 {
 public:
  NodeEvaluator2();
  virtual int64 Run(int i, int j) = 0;
  operations_research::RoutingModel::NodeEvaluator2* GetPermanentCallback();
  virtual ~NodeEvaluator2();

 private:
  virtual bool IsRepeatable() const;
  virtual int64 Run(operations_research::RoutingModel::NodeIndex i,
                    operations_research::RoutingModel::NodeIndex j);
  bool used_as_permanent_handler_;
};

%typemap(cstype) operations_research::RoutingModel::NodeEvaluator2* "NodeEvaluator2";
%typemap(csin) operations_research::RoutingModel::NodeEvaluator2* "$descriptor(ResultCallback2<int64, _RoutingModel_NodeIndex, _RoutingModel_NodeIndex>*).getCPtr($csinput.DisownAndGetPermanentCallback())";

%rename (AddDimensionAux) operations_research::RoutingModel::AddDimension;
%rename (AddDimensionWithVehicleCapacityAux) operations_research::RoutingModel::AddDimensionWithVehicleCapacity;
%rename (SetArcCostEvaluatorOfAllVehiclesAux) operations_research::RoutingModel::SetArcCostEvaluatorOfAllVehicles;
%rename (SetArcCostEvaluatorOfVehicleAux) operations_research::RoutingModel::SetArcCostEvaluatorOfVehicle;

%ignore operations_research::RoutingModel::AddVectorDimension(
    const int64* values,
    int64 capacity,
    const std::string& name);

%ignore operations_research::RoutingModel::AddMatrixDimension(
    const int64* const* values,
    int64 capacity,
    const std::string& name);

%extend operations_research::RoutingModel {
  void AddVectorDimension(const std::vector<int64>& values,
                          int64 capacity,
                          bool fix_start_cumul_to_zero,
                          const std::string& name) {
    DCHECK_EQ(values.size(), self->nodes());
    self->AddVectorDimension(values.data(), capacity,
                             fix_start_cumul_to_zero, name);
  }
}

%ignore operations_research::RoutingModel::WrapIndexEvaluator(
    Solver::IndexEvaluator2* evaluator);

%ignore operations_research::RoutingModel::RoutingModel(
    int nodes, int vehicles,
    const std::vector<std::pair<NodeIndex, NodeIndex> >& start_end);

%rename("%(camelcase)s", %$isfunction) "";

// Wrap cp includes
%include constraint_solver/routing.h
