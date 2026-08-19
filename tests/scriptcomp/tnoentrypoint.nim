# Tests for SetRequireEntryPoint (the `--no-entry-point` feature):
#
# * With requireEntryPoint=false, scripts without an entry point can be
#   compiled for validation. They must still undergo the full semantic pass
#   (so genuine errors are reported), and no output code may be produced.
# * With requireEntryPoint=true (the default), the pre-existing behavior is
#   unchanged: an entry-point-less script reports the "no main" error.

import std/[os, strutils, logging]
import neverwinter/nwscript/compiler
import neverwinter/[restype, resfile, resdir, resman]

const SourcePath = currentSourcePath().splitFile().dir

let rm = newResMan()
rm.add newResFile(SourcePath / "nwtestvmscript.nss")
rm.add newResDir(SourcePath / "corpus")

const LangSpecNWTestScript = ("nwtestvmscript", ResType 2009, ResType 2010, ResType 2064).LangSpec

let cNSS = newCompiler(LangSpecNWTestScript, false, rm)

proc compile(file: string, requireEntryPoint: bool): CompileResult =
  cNSS.setRequireEntryPoint(requireEntryPoint)
  result = cNSS.compileFile(file)

proc check(file: string, requireEntryPoint: bool, expectCode: int32; expectBytecode: bool) =
  let ret = compile(file, requireEntryPoint)
  doAssert ret.code == expectCode, "$# (requireEntryPoint: $#): expected code $#, got $# ($#)" %
    [file, $requireEntryPoint, $expectCode, $ret.code, ret.str]
  doAssert (ret.bytecode != "") == expectBytecode,
    "$# (requireEntryPoint: $#): expected bytecode $#, got $#" %
    [file, $requireEntryPoint, $(if expectBytecode: "generated" else: "absent"), $ret.bytecode.len]
  info "ok: ", file, " requireEntryPoint=", requireEntryPoint, " code=", ret.code

# 623 = STRREF_CSCRIPTCOMPILER_ERROR_NO_FUNCTION_MAIN_IN_SCRIPT (negated)
# 587 = STRREF_CSCRIPTCOMPILER_ERROR_DECLARATION_DOES_NOT_MATCH_PARAMETERS (negated)

check "nomain_valid", false,  0,   false   # validates, nothing generated
check "nomain_valid", true,   623, false   # default behavior unchanged
check "nomain_badsem", false, 587, false   # semantic errors still caught
check "nomain_badsem", true,  623, false   # default behavior unchanged
check "simple",             false,  0,   true    # entry point present: code generated
check "startingcond",       false,  0,   true    # entry point present: code generated
check "neg_badparams",      false,  587, false   # semantics still checked w/ entry point