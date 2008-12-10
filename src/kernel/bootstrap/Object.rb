# Random is the Smalltalk class Random
Random.class_primitive_nobridge 'new'
Random.primitive_nobridge 'next', 'nextInt:'
Random.primitive_nobridge 'next'
RandomInstance = Random.new

class Object
  include Kernel

    # Begin private helper methods

    # primitive_nobridge has max of 3 normal args, 1 star arg, 1 block arg
    #  example with a block argument
    #    primitive_nobridge '_foo*&' , '_foo:a:b:c:d:e:'
    #  example without a block argument
    #    primitive_nobridge '_foo*' , '_foo:a:b:c:d:'


    #  Begin special sends
    #    Reimplementation of these selectors is disallowed by the parser
    #    and they are optimized by code generator to special bytecodes.
    #    Attempts to reimplement them will cause compile-time errors.
    #    Entries here are so that perform will work.
    # _isInteger allows integer?  special sends to non-Numeric objects
    primitive_nobridge '_isInteger', '_isInteger'
    primitive_nobridge '_isFixnum', '_isSmallInteger'
    primitive_nobridge '_isFloat', '_isFloat'
    primitive_nobridge '_isNumber', '_isNumber'
    primitive_nobridge '_isSymbol', '_isSymbol'
    primitive_nobridge '_isBlock', '_isExecBlock'
    primitive_nobridge '_isArray', '_isArray'
    primitive_nobridge '_isHash', '_isRubyHash'
    primitive_nobridge '_isString', '_isOneByteString'
    primitive_nobridge '_isRegexp', '_isRegexp'
    primitive_nobridge '_isRange', '_isRange'
    # End special sends

    #  following are installed by RubyContext>>installPrimitiveBootstrap
    #    primitive_nobridge 'class', 'class' # installed in Object
    #  end installPrimitiveBootstrap

    #  Private method _each: contains on:do: handler for RubyBreakException ,
    #  all env1 sends of each& are compiled as sends of _each&
    #  Attempts to reimplement _each& will fail with a compile error.
    primitive_nobridge '_each&', '_rubyEach:'

    # _storeRubyVcGlobal is used by methods that need to store into
    #   caller's caller's definition(if any) of $~ or $_  . 
    #  Receiver is value to be stored.
    #  An argument of 0 specifies $~ , 1 specifies $_  .
    primitive_nobridge '_storeRubyVcGlobal' , '_storeRubyVcGlobal:'
    #  _getRubyVcGlobal returns caller's caller's value of $~ or $_ , or nil 
    primitive_nobridge '_getRubyVcGlobal' , '_getRubyVcGlobal:'

    # End private helper methods

    primitive_nobridge '==', '='
    primitive 'halt'
    primitive 'hash'
    primitive 'object_id', 'asOop'
    primitive '__id__' , 'asOop'

    #  not   is a special selector,
    #   GsComSelectorLeaf>>selector:  translates #not to bytecode Bc_rubyNOT
    # primitive 'not'

    primitive 'nil?' , '_rubyNilQ'

    # rubySend: methods implemented in .mcz
    primitive_nobridge 'send',  'rubySend:'
    primitive_nobridge 'send',  'rubySend:with:'
    primitive_nobridge 'send',  'rubySend:with:with:'
    primitive_nobridge 'send',  'rubySend:with:with:with:'
    primitive_nobridge 'send&', 'rubySend:block:'
    primitive_nobridge 'send&', 'rubySend:with:block:'
    primitive_nobridge 'send&', 'rubySend:with:with:block:'
    primitive_nobridge 'send&', 'rubySend:with:with:with:block:'
    primitive          'send*&' , 'rubySend:withArgs:block:'

    #  'send:*&' , '__send__:*&' special cased in  installBridgeMethodsFor ,
    #    any other   def send;...  end   gets no bridges  during bootstrap
    #    to allow reimplementation of  send  for methods updating $~ , $_

    #  __send__ defined per MRI, non-overrideable version of send
    #  redefinition of __send__  disallowed by parser after bootstrap finished.
    primitive_nobridge '__send__',  'rubySend:'
    primitive_nobridge '__send__',  'rubySend:with:'
    primitive_nobridge '__send__',  'rubySend:with:with:'
    primitive_nobridge '__send__',  'rubySend:with:with:with:'
    primitive_nobridge '__send__&', 'rubySend:block:'
    primitive_nobridge '__send__&', 'rubySend:with:block:'
    primitive_nobridge '__send__&', 'rubySend:with:with:block:'
    primitive_nobridge '__send__&', 'rubySend:with:with:with:block:'
    primitive          '__send__*&' , 'rubySend:withArgs:block:'

    primitive 'dup', '_basicCopy'
    primitive 'clone', '_basicCopy'

    primitive 'freeze', 'immediateInvariant'
    primitive 'frozen?', 'isInvariant'

    primitive_nobridge 'respond_to?', 'rubyRespondsTo:'

    # install this prim so  anObj.send(:kind_of?, aCls)   will work
    primitive_nobridge 'kind_of?' , '_rubyKindOf:'

    # install this prim so  anObj.send(:is_a?, aCls)   will work
    primitive_nobridge 'is_a?' , '_rubyKindOf:'

    def respond_to?(aSymbol, includePrivateBoolean)
      # Gemstone: the argument includePrivateBoolean is ignored
      respond_to?(aSymbol)
    end

    primitive 'print_line', 'rubyPrint:'

    # pause is not standard Ruby, for debugging only .
    #  trappable only by an Exception specifying exactly error 6001
    primitive 'pause', 'pause'

    #                                   rubyInspect comes from .mcz
    primitive_nobridge '_inspect', '_rubyInspect:'

    def inspect(touchedSet=nil)
      self._inspect(touchedSet)
    end

    #  following 3 prims must also be installed in Behavior
    primitive_nobridge '_instVarAt', 'rubyInstvarAt:'
    primitive_nobridge '_instVarAtPut', 'rubyInstvarAt:put:'
    primitive_nobridge 'instance_variables', 'rubyInstvarNames'

    def instance_variable_get(a_name)
      a_name = Type.coerce_to(a_name, String, :to_str)
      unless (a_name[0].equal?( ?@ ))
        raise NameError, "`#{a_name}' is not allowed as an instance variable name"
      end
      _instVarAt(a_name.to_sym)
    end

    def instance_variable_set(a_name, a_val)
      a_name = Type.coerce_to(a_name, String, :to_str)
      unless (a_name[0].equal?( ?@ ))
        raise NameError, "`#{a_name}' is not allowed as an instance variable name"
      end
      _instVarAtPut(a_name.to_sym, a_val)
      a_val
    end

    primitive 'method', 'rubyMethod:'

    def ===(obj)
        self == obj
    end

    # block_given?  is implemented by the ruby parser .
    #   do not code any definition of block_given? here .
    # Attempts to reimplement  block_given?  will fail with a compile error.

    def initialize(*args)
       self
    end

    # equal?  is implemented by the ruby parser and optimized to
    #  a special bytecode by the code generator.  
    # Attempts to reimplement equal? will fail with a compile error.

    def eql?(other)
      self == other
    end

  def extend(*modules)
    if (modules.length > 0)
      cl = class << self
        self
      end
      modules.each{ |aModule| cl.include(aModule) }
    end
  end

  def flatten_onto(output)
    output << self
    output
  end

    def loop
        raise LocalJumpError, "no block given" unless block_given?

        while true
            yield
        end
    end

    def pretty_inspect
      inspect;
    end

    def raise(err, str)
        err.signal(str)
    end

    def raise(err)
        err.signal(nil)
    end

    def raise
        RuntimeError.signal(nil)
    end

    def rand(n=nil)
        if n
            RandomInstance.next(n)
        else
            RandomInstance.next
        end
    end

    def to_a
       # remove this method for MRI 1.9 compatibility
       [ self ]
    end

    def to_fmt
      to_s
    end

    def to_s
      self.class.name.to_s
    end

    primitive_nobridge '_instance_eval', 'rubyEvalString:with:'
 
    def instance_eval(*args)
      # bridge methods would interfere with VcGlobals logic
      raise ArgumentError, 'wrong number of args'
    end

    def instance_eval(str)
      string = Type.coerce_to(str, String, :to_str)
      vcgl = Array.new(2)
      vcgl[0] = self._getRubyVcGlobal(0);
      vcgl[1] = self._getRubyVcGlobal(1);
      res = _instance_eval(string, vcgl)
      vcgl[0]._storeRubyVcGlobal(0)
      vcgl[1]._storeRubyVcGlobal(1)
      res
    end

    def instance_eval(str, file=nil)
      string = Type.coerce_to(str, String, :to_str)
      vcgl = Array.new(2)
      vcgl[0] = self._getRubyVcGlobal(0);
      vcgl[1] = self._getRubyVcGlobal(1);
      res = _instance_eval(string, vcgl)
      vcgl[0]._storeRubyVcGlobal(0)
      vcgl[1]._storeRubyVcGlobal(1)
      res
    end

    def instance_eval(str, file=nil, line=nil)
      # TODO: Object#instance_eval: handle file and line params
      string = Type.coerce_to(str, String, :to_str)
      vcgl = Array.new(2)
      vcgl[0] = self._getRubyVcGlobal(0);
      vcgl[1] = self._getRubyVcGlobal(1);
      res = _instance_eval(string, vcgl)
      vcgl[0]._storeRubyVcGlobal(0)
      vcgl[1]._storeRubyVcGlobal(1)
      res
    end

    primitive_nobridge 'instance_eval&', 'rubyEval:'

    # Object should NOT have a to_str.  If to_str is implementd by passing
    # to to_s, then by default all objects can convert to a string!  But we
    # want classes to make an effort in order to convert their objects to
    # strings.
    #
    # def to_str
    #   to_s
    # end

    def _isBehavior
      false
    end

    def instance_of?(cls)
      # Modified from RUBINIUS
      if self.class.equal?(cls)
        true
      else
        unless cls._isBehavior 
          raise TypeError, 'expected a Class or Module'
        end
        false
      end
    end

end
