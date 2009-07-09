# Ruby support for the rake tasks in dev.rake.  Support for managing the
# development environment.

# ######################################################################
#                           TOPAZ COMMAND STRINGS
# ######################################################################
# The following +tc_*+ methods generate topaz command strings based on the
# parameters passed to them.

# Returns a topaz command string that reloads the primitives
# (src/kernel/kernel.rb) and commits the DB.
def tc_reload_prims
  <<-END.margin
    | omit resultcheck
    | input $GEMSTONE/upgrade/ruby/reloadprims.topaz
  END
end

def tc_ensure_prims
  <<-END.margin
    |omit resultcheck
    |run
    |RubyContext ensurePrimsLoaded .
    |%
    |exit
  END
end


# Returns a topaz command string that runs the set of passing vm tests
# in src/test/vmunit.conf
def tc_run_vmunit
  <<-END.margin
    |omit resultcheck
    |run
    |RubyContext _runVmUnit
    |%
    |exit
  END
end

# Returns a topaz command string that runs the benchmarks
def tc_run_benchmarks
  <<-END.margin
    |inp #{"rakelib/allbench.inp"}
  END
end

# Returns a topaz command string that will generate Ruby files that expose
# every smalltalk class.
def tc_gen_st_wrappers
  <<-END.margin
    |omit resultcheck
    |run
    |RubyContext createSmalltalkFFIWrappers
    |%
    |exit
  END
end

# Returns a topaz command string that will load the native parser
def tc_load_native_parser
  <<-END.margin
    |inp #{"src/kernel/parser/loadrp.inp"}
  END
end

# # Returns a topaz command string that loads ../latest.mcz and commits the DB.
# def tc_load_mcz
#   <<-END.margin
#     |output push loadmcz.out
#     |display resultcheck
#     |run
#     || fileRepo aName ver |
#     |fileRepo := MCDirectoryRepository new directory: (FileDirectory on: '../').
#     |aName := 'latest.mcz'.
#     |
#     |ver := fileRepo loadVersionFromFileNamed: aName .
#     |ver class == MCVersion ifFalse:[ aName error:'not found in repos' ].
#     |GsFile gciLogServer: ver printString .
#     |ver load .
#     |GsFile gciLogServer: 'load done'.
#     |^ true
#     |%
#     |commit
#     |exit
#   END
# end
