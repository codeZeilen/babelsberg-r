class ArrayConstraintVariable < ConstraintObject
  attr_writer :constraint_variables

  # A metaobject to hold multiple constraints over ranges of the
  # array.
  class RangeConstraint < ConstraintObject
    def initialize(constraints)
      @constraints = constraints
    end

    def enable(strength = :required)
      @constraints.each do |c|
        c.enable(strength)
      end
    end

    def disable
      @constraints.each do |c|
        c.disable
      end
    end
  end

  def initialize(ary)
    @ary = ary
    @constraint_variables = @ary.collect do |var|
      __constrain__ { var }
    end
  end

  def sum
    return 0 if @ary.empty?
    @constraint_variables[0] + self[1..-1].sum
  end

  def __size
    @ary.size
  end

  def length
    @length = @ary.size unless @length
    __constrain__ { @length }
  end
  alias size length

  def [](*args)
    idx, l = args
    if idx.is_a? Numeric and (l.nil? or l == 1)
      idx = idx + @ary.size if idx < 0
      if idx >= @ary.size
        a = 0
        @constraint_variables[idx] = __constrain__ { a }
      end
      @constraint_variables[idx]
    else
      var = ArrayConstraintVariable.new(@ary[*args])
      var.constraint_variables = @constraint_variables[*args]
      var
    end
  end

  def ==(other)
    return false unless other.is_a?(Array) || other.is_a?(self.class)
    equality_constraints = [self.length == other.length]
    os = other.is_a?(self.class) ? other.__size : other.size

    (0...(@ary.size > os ? @ary.size : os)).each do |idx|
      equality_constraints << (self[idx] == (other[idx] || 0))
    end
    r = RangeConstraint.new(equality_constraints)
    r.enable
    r
  end

  # VM interface
  def value
    result = @ary.dup

    if @length
      if result.size < (l = @length)
        while (l -= 1) > 0
          result << 0
        end
      else
        result = result[0...@length] if @length
      end
    end

    @constraint_variables.each_with_index do |cv, idx|
      result[idx] = cv.value if cv && cv.value
    end
    result
  end

  def suggest_value(val)
    initialize(val)
  end

  def method_missing(method, *args)
    raise "Cannot solve array constraints using #{method}"
  end
end

class Array
  def for_constraint(name)
    ArrayConstraintVariable.new(self)
  end

  def assign_constraint_value(val)
    replace(val)
  end
end
