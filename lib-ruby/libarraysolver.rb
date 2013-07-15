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
    return 0 if value.empty?
    @constraint_variables[0] + self[1..-1].sum
  end

  def __size
    value.size
  end

  def length
    @length = @constraint_variables.size unless @length
    __constrain__ { @length }
  end
  alias size length

  def [](*args)
    idx, l = args
    ary = value
    idx = idx.value if idx.is_a? ConstraintObject
    if idx.is_a? Numeric and (l.nil? or l == 1)
      idx = idx + ary.size if idx < 0
      if idx >= @constraint_variables.size
        a = 0.0
        @constraint_variables[idx] = __constrain__ { a }
      end
      if l == 1
        [@constraint_variables[idx]]
      else
        @constraint_variables[idx]
      end
    else
      var = ArrayConstraintVariable.new(ary[*args])
      var.constraint_variables = @constraint_variables[*args]
      var
    end
  end

  def ==(other)
    return false unless other.is_a?(Array) || other.is_a?(self.class)
    ary = value
    equality_constraints = [self.length == other.length]
    os = other.is_a?(self.class) ? other.__size : other.size

    (0...(ary.size > os ? ary.size : os)).each do |idx|
      equality_constraints << (self[idx] == (other[idx] || 0))
    end
    r = RangeConstraint.new(equality_constraints)
    r.enable
    r
  end

  def alldifferent?
    raise "Need Z3 for this" unless defined? Z3
    return true if @constraint_variables.empty?
    always { @constraint_variables.alldifferent? }
  end

  include Enumerable
  def each_with_index(&block)
    i = 0
    ary = value
    while i < ary.size
      yield self[i], i
      i += 1
    end
    true
  end

  # VM interface
  def value
    result = @ary.dup

    if @length
      if @constraint_variables.size > @length
        @length = @constraint_variables.size
      end
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
    raise "Assignment of constrained Arrays not implemented yet"
  end

  def method_missing(method, *args)
    raise "Cannot solve array constraints using #{method}"
  end
end

class Array
  def for_constraint(name)
    if self.all? { |e| e.is_a? Numeric }
      ArrayConstraintVariable.new(self)
    end
  end

  def assign_constraint_value(val)
    replace(val)
  end
end
