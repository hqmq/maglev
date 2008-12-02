#  This file adds entries in the Ruby session methods dictionary,
#    i.e. the session methods dictionary for environment 1.
#  The added entries will have keys being Ruby mangled selectors,
#  and values being Smalltalk methods already in the base server image.
#
#  The ruby method "primitive"  takes one or two String arguments
#     The first arg is an un-mangled Ruby selector, it will be mangled by
#        numArgs timesRepeat: [rubySel := rubySel copyWith: $: ]
#     where numArgs comes from the method found in the base server image.
#  The one exception is methods which take block args, which should include a
#  "&" at the end to indicate this.
#
#     The second arg is the Smalltalk selector.
#     If second arg is not present is is assumed to be exactly the first arg.
#
#     The receiver is a Class in which the session method
#     will be installed, and it is assumed that for that Class,
#     Ruby and Smalltalk classes are identical.  The Smalltalk method
#     installed will be obtained by sending lookupSelector: to
#     the Smalltalk Class which is identical to the receiver.
#
#     The ruby method "primitive" is installed into env 1 by
#         RubyContext>>installPrimitiveBootstrap
#
#     The implementation of "primitive" uses
#       Behavior>>addRubySelector:method:category:

#
# Bootstrap
#
RUBY.class.primitive 'require', 'requireFileNamed:'
RUBY.class.primitive 'load', 'loadFileNamed:'
RUBY.class.primitive 'global', 'installGlobal:'
RUBY.class.primitive 'global', 'installGlobal:name:'

RUBY.require 'kernel/bootstrap/Globals.rb'
RUBY.require 'kernel/bootstrap/GlobalErrors.rb'
RUBY.require 'kernel/bootstrap/Gemstone.rb'

#
# bootstrap
#
RUBY.require 'kernel/bootstrap/Type.rb'
RUBY.require 'kernel/bootstrap/Kernel.rb'
RUBY.require 'kernel/bootstrap/Module.rb'
RUBY.require 'kernel/bootstrap/Behavior.rb'
RUBY.require 'kernel/bootstrap/Class.rb'
RUBY.require 'kernel/bootstrap/Object.rb'

RUBY.require 'kernel/bootstrap/GsHelper.rb'

RUBY.require 'kernel/bootstrap/Fixnum.rb'
RUBY.require 'kernel/bootstrap/Integer.rb'
RUBY.require 'kernel/bootstrap/Float.rb'
RUBY.require 'kernel/bootstrap/Numeric.rb'
RUBY.require 'kernel/bootstrap/Boolean.rb'
RUBY.require 'kernel/bootstrap/Proc.rb'
RUBY.require 'kernel/bootstrap/Array.rb'
RUBY.require 'kernel/bootstrap/Hash.rb'
RUBY.require 'kernel/bootstrap/String.rb'
RUBY.require 'kernel/bootstrap/Symbol.rb'
RUBY.require 'kernel/bootstrap/Regexp.rb'
RUBY.require 'kernel/bootstrap/MatchData.rb'
RUBY.require 'kernel/bootstrap/Exception.rb'

RUBY.require 'kernel/bootstrap/Env.rb'
RUBY.require 'kernel/bootstrap/Errno.rb'
RUBY.require 'kernel/bootstrap/Dir.rb'
RUBY.require 'kernel/bootstrap/File.rb'

RUBY.require 'kernel/bootstrap/Range.rb'

RUBY.require 'kernel/bootstrap/Time.rb'
RUBY.require 'kernel/bootstrap/IO.rb'
RUBY.require 'kernel/bootstrap/Socket.rb'
RUBY.require 'kernel/bootstrap/Comparable.rb'
RUBY.require 'kernel/bootstrap/Set.rb'
RUBY.require 'kernel/bootstrap/UnboundMethod.rb'
RUBY.require 'kernel/bootstrap/Method.rb'
RUBY.require 'kernel/bootstrap/ProcessTms.rb'
RUBY.require 'kernel/bootstrap/Process.rb'
RUBY.require 'kernel/bootstrap/ThrowCatch.rb'
RUBY.require 'kernel/bootstrap/GC.rb'
RUBY.require 'kernel/bootstrap/FileStat.rb'
RUBY.require 'kernel/bootstrap/Thread.rb'

RUBY.require 'kernel/bootstrap/Struct.rb'
RUBY.require 'kernel/bootstrap/Signal.rb'
RUBY.require 'kernel/bootstrap/Math.rb'

# Include the common code after the basic primitives.  This is code that
# should be identical to, or very close to, the Rubinius code.
RUBY.require 'kernel/common/misc.rb'
RUBY.require 'kernel/common/ctype.rb'

RUBY.require 'kernel/common/integer.rb'
RUBY.require 'kernel/common/Enumerable.rb'
RUBY.require 'kernel/common/struct.rb'
RUBY.require 'kernel/common/kernel.rb'
RUBY.require 'kernel/common/string.rb'
RUBY.require 'kernel/common/symbol.rb'
RUBY.require 'kernel/common/dir.rb'
RUBY.require 'kernel/common/file.rb'

# Include the delta code
RUBY.require 'kernel/delta/Module.rb'
RUBY.require 'kernel/delta/Array.rb'
RUBY.require 'kernel/delta/Dir.rb'
RUBY.require 'kernel/delta/Range.rb'
