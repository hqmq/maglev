class BigDecimal
  # most constants defined in bigdecimal1.rb
  # for internal structure see comments under accessors

  #################
  # Class methods #
  #################

  def self.double_fig
    16  # number of significant digits in a Float (8 byte IEEE float)
  end

  # def self.mode ; end # in post_prims/bigdecimal.rb
  # def self.limit ; end # in post_prims/bigdecimal.rb

  def self.induced_from(obj) 
    if obj._isInteger
      self._from_integer(obj)
    elsif obj.kind_of?(BigDecimal)
      obj
    else
      raise TypeError, "failed to convert #{obj.class} into BigDecimal"
    end
  end

  def self.ver
    VERSION
  end

  def self.mode(sym)
    # gets the specified mode
    self._mode(sym)  # implem in post_prims/bigdecimal.rb
  end

  def self.mode(sym, value)
    # sets the specified mode. modification will be transient or persistent
    # per the current state of  Maglev.persistent?
    self._set_mode(sym, value) # implem in post_prims/bigdecimal.rb
  end


  ###############################
  # private Accessors
  ###############################

  def _kind
    @special  # a Fixnum, 0 for finite, 1 for infinite, 2 for nan
  end

  def _digits
    @digits  # a Fixnum or Bignum 
  end

  def _exp
    @exp # a Fixnum , the power of 10 by which to multiply @digits
         # to get the actual value.
         # A value of 0 means that @digits is the integer part
         #   of the BigDecimal and the fractional part is zero.
  end

  def _sign
    @sign  # a Fixnum -1 or 1 
  end

  def _add_to_exp(v)
    @exp = @exp + v
  end

  def _precs
    @precs # number of digits of precision , always > 0 
  end

  ###############################
  # public Accessors
  ###############################

  # Returns the exponent as a Fixnum (or 0 if out of range), such that the absolute value 
  #  of the base is between 0 and 1.  This is not the power function.
  # call-seq:
  #   BigDecimal("0.125e3").exponent => 3
  #   BigDecimal("3000").exponent => 4
  #
  def exponent
    e = @exp
    digs = @digits
    unless digs == 0
      e += digs._decimal_digits_length_approx(false)
    end
    e
  end

  def sign
    kind = @special
    if kind.equal?(0) # finite
      if self.zero? 
        @sign.equal?(1) ? SIGN_POSITIVE_ZERO : SIGN_NEGATIVE_ZERO
      else
        @sign.equal?(1) ? SIGN_POSITIVE_FINITE : SIGN_NEGATIVE_FINITE
      end
    elsif kind.equal?(1) # infinite
       @sign.equal?(1) ? SIGN_POSITIVE_INFINITE : SIGN_NEGATIVE_INFINITE
    else # nan
      SIGN_NaN
    end
  end


  # As for Float.finite? .
  # call-seq:
  #   BigDecimal.new("Infinity").finite?  => false
  #   BigDecimal.new("NaN").finite?  => true
  def finite?
    @special.equal?(0)
  end
  
  def infinite?
    if @special._not_equal?(1)
      return nil # finite or  nan
    else
      return @sign  # returns 1 or -1
    end
  end

  # As for Float.nan? .
  # call-seq:
  #   BigDecimal.new("NaN").nan?  => true
  #   BigDecimal.new("123").nan?  => false
  def nan?
    @special.equal?(2)
  end
  
  # True if positive or negative zero; false otherwise.
  # call-seq:
  #   BigDecimal.new("0").zero?   =>true
  #   BigDecimal.new("-0").zero?  =>true
  def zero?
    #  @digits.to_i == 0 and self.finite?
    @digits == 0 && @special.equal?(0) 
  end

  def precs
    if @special.equal?(0)
      sigfigs = @digits._decimal_digits_length_approx(false)
      p = @precs
      if p.equal?(0)
        p = sigfigs + 10
      end 
    else
      sigfigs = 0  # NaN or Infinity
      p = 1
    end
    [sigfigs, p]
  end

  ###############################
  # Constructors and initializers
  ###############################

  def self._nan
    if RAISE_on_NaN
      raise FloatDomainError , 'result would be a NaN'
    end 
    res = self.allocate
    res._init_nan
  end

  def _init_nan
    @special = 2 
    @precs = UNLIM_PRECISION
    @sign = 1
    @digits = 0
    # @num_digits = 1
    @exp = 0
    self
  end

  def self._infinity(sign)
    if RAISE_on_INF
      raise FloatDomainError , 'result would be infinite'
    end 
    res = self.allocate
    res._init_infinity(sign)
  end

  def _init_infinity(sign_arg)
    @special = 1
    @sign = sign_arg
    @precs = UNLIM_PRECISION
    @digits = 0
    # @num_digits = 1
    @exp = 0
    self
  end

  def _init_zero(sign_arg)
    @special = 0
    @sign = sign_arg
    @precs = UNLIM_PRECISION
    @digits = 0
    # @num_digits = 1
    @exp = 0
    self
  end

  def self._zero(sign)
    res = self.allocate
    res._init_zero(sign)
  end

  def self._from_integer(val)
    res = self.allocate
    res._init_from_integer(val)
  end

  def _init_from_integer(val)
    @special = 0
    if val < 0
      @sign = -1
      val = 0 - val
    else
      @sign = 1
    end
    nd = val._decimal_digits_length_approx(true)
    arr = _reduce_trailing_zeros(val)
    digs = arr[0]
    exp =  arr[1]  # number of trailing zeros removed
    unless exp._isFixnum
      raise FloatDomainError, 'exponent of a BigDecimal exceeds Fixnum range'
    end
    @exp = exp
    @digits = digs
    @precs = UNLIM_PRECISION
    self
  end

  def self._from_float(val)
    res = self.allocate
    res._init_from_float(val)
  end

  def _init_from_float(flt)
    if flt.finite?
      str = flt._as_string  # Smalltalk print format sd.ddddEsee
      len = str.length
      exp_idx = len
      exp_done = false
      exp = 0
      ch = nil
      exp_mult = 1
      until exp_done
        exp_idx -= 1
        ch = str[exp_idx]
        if ch < ?0  # 'E' or exponent sign, either '+' or '-'
          if ch.equal?( ?- )
            exp = exp * -1
            exp_idx -= 1 # now at 'E'
          elsif  ch.equal?( ?+ )
            exp_idx -= 1 # now at 'E'
          end
          exp_done = true
        else
          exp = exp + (ch - ?0 ) * exp_mult 
        end
        exp_mult = exp_mult * 10 
      end
      idx = 0
      ch = str[idx] 
      sign = 1
      if ch.equal?( ?- )
        sign = -1
        idx += 1 # skip leading -
        ch = str[idx]
      end  
      mant_str = ' '
      mant_str[0] = ch
      idx += 2 # skip the two chars 'd.'  
      mant_str << str[idx , exp_idx - idx]
      digs = Integer._from_string(mant_str)
      @digits = digs
      exp += 1 #  flt._as_string produced  d.dddEee , convert to 0.ddddEee for BigDecimal
      exp -= mant_str.length  #  so @digits is an Integer
      @exp = exp 
      @sign = sign
      @special = 0
      @precs = 16  # 16 is the limit of 8 byte IEEE float 
    elsif flt.infinite?
      self._init_infinity( flt > 0.0 ? 1 : -1)
    else
      self._init_nan
    end
    self
  end

  def _init_normal( res_sign, res_digits, res_exp)
    unless res_exp._isFixnum
      raise FloatDomainError, 'exponent of a BigDecimal exceeds Fixnum range'
    end
    @special = 0
    if res_digits.equal?(0)
      res_sign = 1  # canonicalize zero results as positive zero
      res_exp = 0
    end
    @sign = res_sign
    @digits = res_digits
    @exp = res_exp
    self
  end

  def _set_precision( p )
    # a separate method from _init_normal, since Maglev has a max of 3 non-array
    # args to a method, without incurring bridge method or argument wrapping overhead.
    @precs = p
    self
  end

  # call-seq:
  #   BigDecimal("3.14159")   => big_decimal
  #   BigDecimal("3.14159", 10)   => big_decimal
  def initialize(_val, _precs=0)
    # MRI appears to  ignore the precision argument
    v = _val.strip
    first_ch = v[0]
    sgn = 1
    if first_ch.equal?( ?+ )
      first_ch = v[1]
    elsif first_ch.equal?( ?- )
      first_ch = v[1]
      sgn = -1
    end
    if first_ch.equal?( ?N ) && v == "NaN"
      self._init_nan
      return
    elsif first_ch.equal?( ?I ) && v =~ /^[-+]?Infinity$/
      self._init_infinity(sgn)
      return
    end
    @sign = sgn
    @special = 0 
    v = v._delete_underscore
    m = /^\s*(([-+]?)(\d*)(?:\.(\d*))?(?:[EeDd]([-+]?\d+))?).*$/.match(v)
    mant = 0
    expon = 0
    ndigits = 0
    if m._not_equal?(nil) # [
      @sign = sgn
      i_cls = Integer
      frac_str = m[4]
      if frac_str.equal?(nil)
	frac = 0
	nd_frac = 0
      else
	frlen = frac_str.length
	nd_frac = frlen
	if frlen._not_equal?(0) 
	  # strip trailing zeros from fraction
	  fend_idx = frlen - 1
	  while fend_idx > 0 && frac_str[fend_idx].equal?( ?0 )
	    fend_idx -= 1
	  end
	  frlen = fend_idx + 1
	end
	frac_prefix_str = frac_str[0, frlen] # without trailing zeros
	frac = i_cls._from_string( frac_prefix_str )
      end
      int_str = m[3]
      nd_int = int_str.length
      if nd_int.equal?(0) 
        int = 0
      elsif int_str[0].equal?( ?0 )
        int = i_cls._from_string( int_str ) # leading zero digit
      else
        j = nd_int - 1
        if frac_str.equal?(nil)
          # strip trailing zeros off integer to reduce chance of integer overflow
          while int_str[j].equal?( ?0 ) and j > 0 
            expon += 1
            j -= 1
          end
        end
        int = i_cls._from_string( int_str[0, j+1] )
      end
      exp_str =  m[5]
      expon +=  exp_str.equal?(nil) ? 0 : i_cls._from_string(  exp_str )
      if int == 0 && frac != 0   
        expon -= frlen # adjust for decimal point at rhs of internal digits
	# adjust precision for number of leading zeros in fraction
	fidx = 0
	while fidx < frlen && frac_str[fidx].equal?( ?0 )
	  fidx += 1
	  nd_frac -= 1
	end
      elsif frac_prefix_str._not_equal?(nil)
	# multiply int by 10**frac_prefix_str.length
	count = frac_prefix_str.length
	int = _multiply_by_tenpower(int, count)
	expon -= count
      end 
      mant = int + frac
    end # ]
    # MRI appears to ignore precision arg to new  and add about 17 ...
    if nd_frac.equal?(0)
      @precs = UNLIM_PRECISION
    else
      @precs = nd_frac + nd_int + 17
    end
    @digits = mant
    unless expon._isFixnum
      raise FloatDomainError, 'exponent of a BigDecimal exceeds Fixnum range'
    end
    @exp = expon
  end

  ###############
  # Conversions #
  ###############
  
  def to_f
    kind = @special
    sign = @sign
    if kind._not_equal?(0)
      if kind.equal?(1)
        if sign.equal?(1)
          return +1.0/0.0 
        else
          return -1.0/0.0
        end
      end
      return 0.0/0.0 # NaN
    end 
    mant = @digits # an Integer
    expon = 10.0 ** @exp
    f = mant.to_f 
    if sign.equal?( -1 )
      f = f * -1.0
    end
    f = f * expon
    f
  end
  
  def to_i
    if @special._not_equal?(0)
      return nil # NaN or Infinity
    end
    exp = @exp
    val = @digits
    if exp._not_equal?(0) 
      if exp > 0
        val = _multiply_by_tenpower(val, exp)
      else
        val = _divide_by_tenpower(val, 0 - exp)
      end
    end
    if @sign._not_equal?(1)
      val = 0 - val
    end
    val
  end

  def to_s(arg=nil)   # [
    # parse the argument for format specs
    positive = ''
    format =  :eng
    spacing = 0
    if arg._not_equal?(nil)
      if arg._isFixnum
        spacing = arg > 0 ? arg : 0 
      else
        unless arg._isString
          raise TypeError, 'BigDecimal#to_s, expected a String or Fixnum argument'
        end
        if arg.length._not_equal?(0)
          if arg.index( ?+ , 0)._not_equal?(nil)
            positive = '+'
          elsif arg.index( ?\s  , 0)._not_equal?(nil)
            positive = ' '
          end
          if arg.index( ?F , 0)._not_equal?(nil)
            format = :float 
          end
          spacing = arg.to_i
        end
      end
    end
    
    kind = @special
    if kind.equal?(2)
      return 'NaN'
    end

    if @sign.equal?(1) 
      str = positive
    else
      str = '-'
    end

    if kind.equal?(0) # finite
      value = @digits.to_s
      nd = value.length
      expon = @exp
      s_expon = nd + expon # convert to expon for 0.ddddEee 
      if format.equal?( :float )
        # get the decimal point in place
        if s_expon >= nd
          value << ('0' * (s_expon - nd))
          value << '.0' # DECIMAL_POINT.0
        elsif s_expon > 0
          vstr = value[0, s_expon] 
          vstr << ?. # DECIMAL_POINT
          vstr << value[s_expon..-1]
          value = vstr
        elsif s_expon <= 0
          vstr = '0.'  # 0.DECIMAL_POINT
          vstr << ('0' * (0 - s_expon)) 
          vstr <<  value
          value = vstr
        end
      elsif format.equal?( :eng )
        value = '0.' + value  #  0.DECIMAL_POINT + 
        value << ?E # EXP
        value <<  s_expon.to_s
      end
      
      if spacing._not_equal?( 0 )
        radix = '.' # DECIMAL_POINT
        m = /^(\d*)(?:(#{radix})(\d*)(.*))?$/.match(value)
        # left, myradix, right, extra = m[1, 4].collect{|s| s.to_s}
        marr = m[1, 4]
        left = marr[0].to_s
        myradix = marr[1].to_s
        right = marr[2] .to_s
        extra = marr[3].to_s

        right_frags = []
        0.step(right.length, spacing) do |n|
          right_frags.push( right[n, spacing])
        end
        
        left_frags = []
        tfel = left.reverse
        0.step(left.length, spacing) do |n|
          left_frags.unshift( tfel[n, spacing].reverse)
        end
        
        right = right_frags.join(' ').strip
        left = left_frags.join(' ').strip
        value = left.to_s 
        value << myradix.to_s 
        value << right.to_s 
        value << extra.to_s
      end
      str << value
    elsif kind.equal?(1)
      str << 'Infinity'
    end
    return str
  end # ]
  
  def inspect
    str = '#<BigDecimal:'
    parr = self.precs
    str << [nil, "'#{self.to_s}'", "#{parr[0]}(#{parr[1]})"].join(',')
    str << '>'
    return str
  end

  #########################
  # Arithmetic support #
  #########################

  def coerce(other)
    if other._isInteger
      [ BigDecimal._from_integer(other), self ]
    elsif other._isFloat
      [ BigDecimal._from_float(other), self]
    elsif other.kind_of?(BigDecimal)
      [other, self]
    elsif other._isNumeric
      [BigDecimal(other.to_s), self]
    else
      raise TypeError, 'coercion failed'
    end
  end

  def _reduce_precis(an_integer, reduction)
    # reduction is a negative number
    #   reduction is the number of l.s. digits to delete
    # returns an_integer divided by the requisite power of 10  .
    val = an_integer
    count = reduction
    if count > 9
      while count > 12 
	val = val._divide(1000_000_000)
	count -= 9
      end
      val = val._divide(1000);  # count in range 10..12 inclusive
      count -= 3                # count now 7..9
    end
    if count > 0
      divisor = TEN_POWER_TABLE[count] 
      arr = val._quo_rem( divisor , [ nil, nil ] )
      val = arr[0]
      rem = arr[1]
      if rem._not_equal?(0)
        mode = ROUNDING_mode
        if mode.equal?(0) # ROUND_HALF_UP
          if rem > (divisor._divide(2) ) 
            val += 1
          end
        elsif mode.equal?(1) # ROUND_UP
          val += 1
        else 
          # ROUND_DOWN, add nothing
        end
      end
    end
    val
  end

  def _reduce_trailing_zeros(an_integer)
    # removes trailing decimal zero digits from an_integer 
    # returns  [ reduced_integer, count ] ,
    #   where count tells how many trailing zeros were removed.
    val = an_integer
    count = 0
    qr_first = val._quo_rem( 10,  [nil,nil] )
    if qr_first[0]._not_equal?(0) && qr_first[1].equal?(0)
      #  (val > 10) && (val % 10) == 0) == true
      more_than_one_zero = false
      qr = [nil,nil]
      if val >= 1000_000_000 
        val._quo_rem( 1000_000_000 ,  qr )
        while (v_next = qr[0])._not_equal?(0) && qr[1].equal?(0) 
	  # ((val >= 1000_000_000) && (val % 1000_000_000)==0)==true  
	  val = v_next
	  count += 9
	  more_than_one_zero = true
	  val._quo_rem( 1000_000_000, qr)
        end
      end
      val._quo_rem( 1000, qr )
      while (v_next = qr[0])._not_equal?(0) && qr[1].equal?(0) 
	# ((val >= 10000) && (val % 1000)==0)==true  
	val = v_next
	count += 3
	more_than_one_zero = true
	val._quo_rem( 1000, qr )
      end
      if more_than_one_zero
	val._quo_rem( 10 , qr )
      else          
	qr = qr_first
      end
      while (v_next = qr[0])._not_equal?(0) && qr[1].equal?(0)
	# ((val >= 10) && (val % 10).equal?(0))==true
	val = v_next
	count += 1
	val._quo_rem( 10 , qr )
      end
    end
    qr_first[0] = val # reuse qr_first as result array
    qr_first[1] = count
    qr_first
  end

  def _multiply_by_tenpower(an_integer, power)
    val = an_integer
    if power > 0
      while power >= 9
        val = val * 1000_000_000
        power -= 9
      end
      if power > 0
        val = val * TEN_POWER_TABLE[power] 
      end 
    else
      raise ArgumentError , '_multiply_by_tenpower, power <= 0'
    end
    val 
  end

  def _divide_by_tenpower(an_integer, power)
    val = an_integer
    if power > 0
      while power >= 9
        val = val._divide(1000_000_000)
        power -= 9
      end
      if power > 0
        val = val._divide(TEN_POWER_TABLE[power])
      end 
    else
      raise ArgumentError , '_divide_by_tenpower, power <= 0'
    end
    val 
  end

  def _negated
    my_kind = @special
    if my_kind.equal?(0)
      res = self.class.allocate
      res._init_normal(  0 - @sign, @digits , @exp)
      res._set_precision( @precs )
    elsif my_kind.equal?(1)
      res = self.class.allocate
      res._init_infinity( 0 - @sign )
    else
      res = self # nan
    end
    res
  end

  #########################
  # Derived Arithmetic operations 
  #########################

  def +(other)
    unless other.kind_of?(BigDecimal)
      other = self.coerce(other)[0]
    end
    self._add(other, DEFAULT_prec, other._sign)
  end
  
  def sub(other, precs)
    precs = Type.coerce_to( precs, Fixnum, :to_int)
    raise TypeError , 'precision must be >= 0'    if precs < 0
    unless other.kind_of?(BigDecimal)
      other = self.coerce(other)[0]
    end
    self._add(other, precs, 0 - other._sign  )
  end

  def -(other)
    unless other.kind_of?(BigDecimal)
      other = self.coerce(other)[0]
    end
    self._add(other, DEFAULT_prec, 0 - other._sign )
  end

  def *(other)
    self.mult(other, nil)
  end

  def quo(other, prec = nil)
    self.div(other, prec)
  end
  alias / quo

  def remainder(other)
    unless other.kind_of?(BigDecimal)
      other = self.coerce(other)[0]
    end
    mod = self.modulo(other)

    if (@sign * other._sign < 0)
      return mod - other
    else
      return mod
    end
  end

  def modulo(other)
    self.divmod(other)[1]
  end
  alias % modulo

  #########################
  # Fundamental Arithmetic operations 
  #########################


  def add(other, prec_arg)  # [
    prec_arg = Type.coerce_to( prec_arg, Fixnum, :to_int)
    raise TypeError , 'precision must be >= 0'    if prec_arg < 0
    unless other.kind_of?(BigDecimal)
      other = self.coerce(other)[0]
    end
    self._add(other, prec_arg, other._sign)
  end

  def _add(other, prec_arg, other_sign)
    my_kind = @special # 0 for normal, 1 for Infinity, 2 for NaN 
    other_kind = other._kind
    my_sign =  @sign
    unless (my_kind + other_kind).equal?(0)  
      # at least one is not finite
      if my_kind.equal?(2) or other_kind.equal?(2) 
        return self.class._nan  # at least one NaN
      elsif my_kind.equal?(1) and other_kind.equal?(1) and my_sign._not_equal?(other_sign)
        return self.class._nan # infinity + -infinity
      elsif my_kind.equal?(1) 
        return self.class._infinity( my_sign )  #  infinity + x  
      elsif other_kind.equal?(1) 
        return self.class._infinity( other_sign)  # x + infinity  
      end
    end
    my_digs = @digits
    my_exp = @exp
    other_digs = other._digits
    other_exp = other._exp
    if prec_arg.equal?(0)
      if my_digs == 0 and other_sign == my_sign 
        return other  # 0 + other
      elsif other_digs == 0 and other_sign == my_sign
        return self   # self + 0
      end
    end
    my_prec =  @precs
    other_prec = other._precs
    if my_exp < other_exp
      delta_exp = other_exp - my_exp
      other_digs = self._multiply_by_tenpower(other_digs, delta_exp)
      if other_prec < UNLIM_PRECISION
        other_prec += delta_exp
      end
      r_expon = my_exp
    elsif my_exp > other_exp
      delta_exp = my_exp - other_exp
      my_digs = self._multiply_by_tenpower(my_digs, delta_exp)
      if my_prec < UNLIM_PRECISION
        my_prec += delta_exp
      end
      r_expon = other_exp
    else
      r_expon = my_exp
    end
    if my_sign.equal?(other_sign)
      r_digits = my_digs + other_digs
      r_sign = my_sign
    else 
      if my_sign.equal?(-1)
        r_digits = other_digs - my_digs
      else    
        r_digits = my_digs - other_digs 
      end 
      r_sign = 1
      if r_digits < 0
        r_sign = -1
        r_digits = 0 - r_digits
      end
    end
    arr = _reduce_trailing_zeros(r_digits)
    r_digits = arr[0]
    r_expon += arr[1]

    		# adjust precision
    p = my_prec._max(other_prec)
    if prec_arg._not_equal?(0)
      p = prec_arg._min( p )
    end
    nd = r_digits._decimal_digits_length_approx(true)
    rd = nd - p 
    if rd > 0  #  rd is number of digits to omit
      r_digits = _reduce_precis(r_digits, rd)
      r_expon += rd
    end

    res = self.class.allocate
    res._init_normal( r_sign, r_digits, r_expon)
    res._set_precision(p)
  end # ]

  def mult(other, prec_arg = nil) # [
    if prec_arg.equal?(nil)
      prec_arg = DEFAULT_prec
    else
      prec_arg = Type.coerce_to( prec_arg, Fixnum, :to_int)
      raise TypeError , 'precision must be >= 0'   if prec_arg < 0
    end
    unless other.kind_of?(BigDecimal)
      other = self.coerce(other)[0]
    end
    my_kind = @special # 0 for normal, 1 for Infinity, 2 for NaN 
    other_kind = other._kind
    my_sign =  @sign
    other_sign = other._sign
    r_sign =  my_sign * other_sign 
    unless (my_kind + other_kind).equal?(0)  
      my_zero = self.zero?
      other_zero = other.zero?
      if my_kind.equal?(2) or other_kind.equal?(2)
        return self.class._nan # at least one is Nan
      elsif (my_kind.equal?(1) and other_zero) or (my_zero and other_kind.equal?(1) )
        return self.class._nan   # a zero * an Infinity --> nan
      elsif my_kind.equal?(1)   # self is an Infinity
        if ( r_sign < 0) == my_sign < 0    
          return self 
        else
          return self._negated
        end
      elsif other_kind.equal?(1)  # other is an Infinity
        if ( r_sign < 0) == my_sign < 0
          return other
        else
          return other._negated
        end
      else
        raise 'logic error BigDecimal#mult non-finite'
      end
    end
    my_digs = @digits
    other_digs = other._digits
    if my_digs == 0 or other_digs == 0
      res = self.class._zero( r_sign )
    end
    my_exp = @exp
    other_exp = other._exp
 
    r_digs = my_digs * other_digs 
    r_expon =  my_exp + other_exp 

    arr = _reduce_trailing_zeros( r_digs )
    r_digits = arr[0]
    r_expon += arr[1]

    my_prec =  @precs
    other_prec = other._precs
    		# adjust precision
    p = my_prec._max(other_prec)
    if prec_arg._not_equal?(0)
      p = prec_arg._min( p )
    end
    nd = r_digits._decimal_digits_length_approx(true)
    rd = nd - p 
    if rd > 0  #  rd is number of digits to omit
      r_digits = _reduce_precis(r_digits, rd)
      r_expon += rd
    end

    res = self.class.allocate
    res._init_normal( r_sign, r_digits, r_expon)
    res._set_precision(UNLIM_PRECISION)
  end # ]
  
  def div(other, prec_arg = nil) # [
    if prec_arg.equal?(nil)
      prec_arg = DEFAULT_prec
    else
      prec_arg = Type.coerce_to( prec_arg, Fixnum, :to_int)
      raise TypeError , 'precision must be >= 0'   if prec_arg < 0
    end
    unless other.kind_of?(BigDecimal)
      other = self.coerce(other)[0]
    end
    my_kind = @special # 0 for normal, 1 for Infinity, 2 for NaN
    other_kind = other._kind
    my_sign =  @sign 
    other_sign = other._sign 
    r_sign =  my_sign * other_sign
    unless (my_kind + other_kind).equal?(0)
      # at least one is not finite
      if my_kind.equal?(2) or other_kind.equal?(2) 
        return self.class._nan  # at least one NaN
      elsif other_kind.equal?(1)  # other is infinite
        if my_kind.equal?(1)
          return self.class._nan  # infinity/infinity
        elsif prec_arg.equal?(0)
          return self.class._nan  # finite/infinity and no precision specified
        else
          return self.class._zero(1) # positive zero
        end
      elsif my_kind.equal?(1) # infinity / finite
        if prec_arg.equal?(0)
          return self.class._nan # no precision specified
        else
          return self.class._infinity( r_sign  )
        end
      end
    end
    my_digs = @digits
    my_exp = @exp
    other_digs = other._digits
    other_exp = other._exp
    if other_digs.equal?(0)
      if RAISE_on_ZERODIV
        raise FloatDomainError, 'divide by zero'
      end
      if my_digs == 0 or prec_arg.equal?(0)
        return self.class._nan # 0 / 0 , or finite/0 with default precision
      else
        return self.class._infinity( other_sign )  # finite non-zero / 0
      end
    end

    my_nd = my_digs._decimal_digits_length_approx(true)
    other_nd = other_digs._decimal_digits_length_approx(true)
    delta_exp = 0
    other_nd_lim = other_nd + 35 # to meet accuracy required by remainder_spec.rb
    if my_nd < other_nd_lim
      delta_exp = other_nd_lim - my_nd 
    end
    if prec_arg > 0 
      delta_exp = delta_exp._max( prec_arg + 5 )
    end
    my_prec =  @precs
    other_prec = other._precs
    if my_prec < UNLIM_PRECISION && other_prec < UNLIM_PRECISION
      delta_exp = delta_exp._max( my_prec._max(other_prec) )
    end
    if delta_exp > 0
      my_digs = _multiply_by_tenpower(my_digs, delta_exp) 
    end
    r_digits = my_digs._divide( other_digs )
    r_expon = my_exp - delta_exp - other_exp

    		# adjust precision
    p = my_prec._max(other_prec)
    if prec_arg._not_equal?(0)
      p = prec_arg._min( p )
    end
    nd = r_digits._decimal_digits_length_approx(true)
    rd = nd - p 
    if rd > 0  #  rd is number of digits to omit
      r_digits = _reduce_precis(r_digits, rd)
      r_expon += rd
    end
      
    res = self.class.allocate
    res._init_normal( r_sign, r_digits, r_expon)
    res._set_precision(UNLIM_PRECISION)
  end # ]

  def divmod(other_arg) # [
    other = other_arg
    unless other.kind_of?(BigDecimal)
      other = self.coerce(other)[0]
    end
    my_kind = @special
    other_kind = other._kind
    if my_kind._not_equal?(0) # self.infinite? or self.nan?
      cls = self.class
      return [ cls._nan, cls._nan ]
    end
    if other_kind._not_equal?(0) or other.zero?
      cls = self.class
      return [ cls._nan, cls._nan ]
    end

    first = (self.div(other, 0) ).floor(0)  # (first / other).floor
    prod = first.mult(other, 0) 
    second = self._add( prod, 0, 0 - prod._sign )   #  self - (first * other)
if Gemstone.session_temp(:TrapBd) ; nil.pause ; end
    if other_arg._isFloat
      res = [ first.to_i , second.to_f ]
    else
      res = [ first , second ]
    end
    res 
  end # ]

  def sqrt(prec_arg)   # [
    # precision arg is required, not optional
    prec_arg = Type.coerce_to( prec_arg, Fixnum, :to_int)
    raise TypeError , 'precision must be >= 0'   if prec_arg < 0

    my_sign = @sign
    if my_sign.equal?(-1)
      unless self.zero?
        raise FloatDomainError , 'BigDecimal#sqrt, receiver is < 0 '
      end
    end
    if @special.equal?(2)
      raise FloatDomainError , 'BigDecimal#sqrt, receiver is NaN'
    end
    true_exp = self.exponent # the true exponent
    # avoid Infinity on conversion, Float handles E+-307 approx
    if true_exp > 300   
      d_exp = true_exp - 300
      if (d_exp & 1) == 1
        d_exp += 1 # make it even
      end
      divisor = self.class.allocate
      divisor._init_normal( 1, 1, d_exp )
      divisor._set_precision(UNLIM_PRECISION)
      reduced_bd = self.div(divisor, 0)
      r_expon = d_exp._divide(2)
    elsif true_exp < -300
      m_exp = 0 - (true_exp + 300) 
      if (m_exp & 1) == 1
        m_exp += 1 # make it even
      end
      mu = self.class.allocate
      mu._init_normal( 1, 1, m_exp )
      mu._set_precision(UNLIM_PRECISION)
      reduced_bd = self.mult(mu, 0)
      r_expon = (0 - m_exp)._divide(2)
    else
      reduced_bd = self
      r_expon = 0
    end
    f = reduced_bd.to_f
    sq = f.sqrt   # use the Float math support 
    sq_bd = self.class._from_float(sq)
    if prec_arg < 14
      res = sq_bd
      res._add_to_exp( r_expon )
      if prec_arg > 0
        res = res._add(self.class._zero(1), prec_arg, 1) # to reduce precision
      end
    else
      # Newtons method iteration to make result more precise
      # see http://en.wikipedia.org/wiki/Newton's_method
      margin = sq_bd.clone
      margin._add_to_exp( 0 - prec_arg - 1) # margin = sq / (10**(prec_arg + 1))
      x = sq_bd
      x._add_to_exp( r_expon )
      x._set_precision(UNLIM_PRECISION)
      done = false
      my_sign_negated = 0 - my_sign
      until done
        delta = (x.mult(x, 0))._add(self, 0, my_sign_negated ) # delta = (x * x) - self 
        delta_sign = delta._sign
        if delta_sign < 0
          diff = margin._add(delta, 0, delta_sign )
        else
          diff = margin._add(delta, 0, 0 - delta_sign ) # margin - sub
        end
        done = diff._sign > 0 # done = margin > delta 
        unless done
          # goal is x,  such that x*x == self
          # f(x) is   x**2 - self
          # first derivative f'(x) is   2*x
          # next_x = x - ( f(x) / f'(x)) 
          next_x = x - (((x * x) - self) / (2 * x))
          x = next_x
        end
      end    
      res = x
    end
    res
  end # ]

  # Raises self to an integer power.
  def power(other) # [
    other = Type.coerce_to( other, Fixnum, :to_int)
    kind = @special
    if kind._not_equal?(0) # not finite
      return self.class._nan
    elsif self.zero?
      if other > 0
        return self.class._zero(1) 
      elsif other == 0
        return self.class._from_integer( 1 )
      else
        return self.class._infinity(1)
      end
    end
    if other == 0 
      one = self.class._from_integer( 1 )
      if self == one 
        return one
      end
    end
    if other < 0
      # res = one.div( (self.power( other.abs) ) , 0)
      my_pwr = self.power( 0 - other )
      one = self.class._from_integer( 1 )
      denom = self.class._from_integer( my_pwr._digits )
      q = one.div( denom )
      d_pwr = self.class.allocate
      d_pwr._init_normal( 1 , 1 , 0 - my_pwr._exp )
      d_pwr._set_precision(UNLIM_PRECISION)
      res = q.mult(d_pwr, 0)  # q * (1 * 10**(0 - my_pwr._exp))
      return res
    end
    nd = @digits ** other
    if (@sign == -1)
      nsign = (other & 1) == 0 ? 1 : -1 #  even arg --> positive result
    else
      nsign = 1
    end
    nexp = @exp * other   
    arr = _reduce_trailing_zeros(nd)
    nd = arr[0]
    nexp += arr[1]
    res = self.class.allocate
    res._init_normal( nsign, nd, nexp)
    res._set_precision(UNLIM_PRECISION)
    res
  end # ]

  alias ** power
  
  # Unary minus
  def -@
    self._negated
  end

  def <=>(other) # [
    my_kind = @special
    if other.equal?(self)
      if my_kind.equal?(2)
        return nil # NaN's not comparable
      end
      return 0
    end
    unless other._isNumeric
      return nil
    end
    if !other.kind_of?(BigDecimal)
      return self <=> self.coerce(other)[0]
    end
    other_kind = other._kind
    if (my_kind + other_kind)._not_equal?(0)  
      # not both finite
      if my_kind.equal?(2) or other_kind.equal?(2) 
        # at least one is nan
        return nil
      end 
      if my_kind.equal?(1) 
        if other_kind.equal?(1)
          # both infinite
          return @sign <=> other._sign
        else
          return @sign # self infinite, other finite
        end
      else
        # self finite, other infinite
        return  0 - other._sign 
      end
    end
    res = (@sign <=> other._sign)
    digs = @digits
    if res._not_equal?(0)
      if digs == 0 and other._digits == 0
        return 0
      else
        return res
      end
    end
    res = (@exp <=> other._exp)
    if res.equal?(0)
      return @digits <=> other._digits
    end
    diff = self._add(other , 0, 0 - other._sign )  # self - other
    if diff.zero?
      return 0
    end
    return diff._sign
  end # ]
  
  def eql?(other)
    if other._isNumeric
      if other.kind_of?(BigDecimal)
        return (self <=> other).equal?(0)
      else
        oth = self.coerce(other)[0]
        return (self <=> oth).equal?(0)
      end
    else 
      return false
    end
  end
  alias === eql?
  
  ####################
  # Other operations #
  ####################
  
  
  def abs
    if @sign.equal?(1) 
      self
    else
      self._negated
    end
  end

  def _truncate(n, delta_for_fraction) # [
    kind = @special
    if kind._not_equal?(0) 
      return self  # Infinity or NaN
    end
    my_exp = @exp
    digs = @digits
    if n._not_equal?(0)
      if n > 0
	if my_exp < 0
	  nd_frac = 0 - my_exp 
	  rd = nd_frac - n # rd is number of digits to omit
	  if rd > 0
	    digs = _reduce_precis(digs, rd)
	    my_exp += rd
	  end
	end
      else # n < 0 , zeroing digits to left of decimal
        rd = (0 - n) - my_exp
        if rd > 0
          digs = _reduce_precis(digs, rd)
          my_exp += rd
        end
      end
      res = self.class.allocate
      res._init_normal( @sign , digs, my_exp)
      res._set_precision(UNLIM_PRECISION)
    else  # n == 0
      int_val = digs 
      if my_exp._not_equal?(0) 
        if my_exp > 0
          int_val = _multiply_by_tenpower(digs, my_exp)
        else
          int_val = _divide_by_tenpower(digs, 0 - my_exp)
        end
      end
      my_sign = @sign
      if my_sign._not_equal?(1)
        int_val = 0 - int_val
      end
      if my_exp < 0 and delta_for_fraction != 0
        # has a fractional part
        pwr = 10 ** (0 - my_exp)
        frac = digs % pwr 
        if frac > 0 && my_sign.equal?(delta_for_fraction)
          int_val += delta_for_fraction 
        end
      end
      res = self.class.allocate
      res._init_from_integer(int_val) 
    end
  end # ]
  
  def ceil(n = 0)
    # if n == 0 , returns a BigDecimal with integer greater or equal to self
    # if n > 0,  returns copy of receiver 
    #    with precision reduced to n digits to right of the decimal point
    # if n < 0, zeros (0-n) digits to left of decimal point
    n = Type.coerce_to( n, Fixnum, :to_int)
    self._truncate(n, 1)
  end
  
  def fix
    #  returns a BigDecimal with integer part of self
    my_exp = @exp
    if my_exp < 0
      int_val = self.to_i
      self.class._from_integer(int_val)
    else   
      self  # contains no fractional part
    end
  end
  
  def floor(n = 0)
    # if n == 0, returns a BigDecimal with integer value smaller or equal to self
    # if n > 0,  returns copy of receiver 
    #    with precision reduced to n digits to right of the decimal point
    # if n < 0, zeros (0-n) digits to left of decimal point
    n = Type.coerce_to( n, Fixnum, :to_int)
    self._truncate(n, -1)
  end
  
  def frac
    # returns a BigDecimal the fractional part of self
    kind = @special
    if kind._not_equal?(0)
      return self  # Infinity or NaN
    end
    my_exp = @exp
    if my_exp < 0
      # has a fractional part
      pwr = 10 ** (0 - my_exp)
      frac = @digits % pwr
      if frac > 0
        res = self.class.allocate
        res._init_normal(@sign, frac , my_exp)
        return res._set_precision(UNLIM_PRECISION)
      end
    end
    return self.class._zero(1)
  end
    
  def split
    # returns an Array, [ sign , digits_string, 10 , exponent ]
    #   sign is zero for NaN
    #   digits_string are the significant digits
    kind = @special
    if kind._not_equal?(0)
      if kind.equal?(1)
        return [ @sign, 'Infinity', 10, 0] 
      else
        return [ 0, 'NaN', 10, 0] 
      end
    end
    [ @sign , @digits.to_s , 10, self.exponent ]
  end
  
  def truncate(n = 0)
    # if n == 0, returns the integer part as a BigDecimal
    # if n > 0,  returns copy of receiver
    #    with precision reduced to n digits to right of the decimal point
    # if n < 0, zeros (0-n) digits to left of decimal point
    n = Type.coerce_to( n, Fixnum, :to_int)
    self._truncate(n, 0)
  end

end