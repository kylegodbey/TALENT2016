%module hffs
%include "std_string.i"
%include "std_vector.i"
%include "std_vectora.i"
%include "exception.i"
%exception
{
  try
  {
    $action
  }
  catch (const std::runtime_error& e) {
    SWIG_exception(SWIG_RuntimeError, e.what());
  }
  catch (const std::logic_error& e) {
    SWIG_exception(SWIG_IndexError, e.what());
  }
}

%{
#define SWIG_FILE_WITH_INIT

#include "Basis.h"
#include "SpBasis.h"
#include "ReducedSpBasis.h"
#include "System.h"
#include "NeutronDrop.h"
#include "Nucleus.h"
#include "Solver.h"
#include "HartreeFock.h"
#include "HartreeFockBogo.h"
%}

%include "armanpy.i"


%include "Basis.h"
%include "SpBasis.h"
%include "ReducedSpBasis.h"
%include "System.h"
%include "NeutronDrop.h"
%include "Nucleus.h"
%include "Solver.h"
%include "HartreeFock.h"
%include "HartreeFockBogo.h"
