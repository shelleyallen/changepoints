require 'narray'
require 'statsample'
require 'gsl'

class MathArray
  attr_accessor :arr

  def initialize(*args)
    case args.length
    when 1
      case args[0]
      when MathArray
        @arr = args[0].arr
      when NArray
        @arr = args[0]
      when Array
        @arr = NArray[*args[0]].to_f
      end
    when 2
      @arr = NArray.float(args[0]).fill(args[1])
    end
  end
  
  def self.new_2d(i,j, val)
    self.new(NArray.float(i, j).fill(val))
  end
  
  def set(i_range, j_range, v)
    v = v.to_na if v.is_a?(MathArray)
    
    @arr[i_range, j_range] = v
  end
  
  def reverse
    @arr[(@arr.length-1)..0]
  end
  
  def get(i_range, j_range)
    MathArray.new(@arr[i_range, j_range])
  end
  
  def sum_squares
    ((@arr - @arr.mean)**2).sum
  end
  
  def stddev_samp
    Math.sqrt(self.sum_squares/(@arr.length - 1))
  end
  
  def stddev_pop
    Math.sqrt(self.sum_squares/@arr.length)
  end
  
  def gt(i, j)
    j = j.to_na if j.is_a?(MathArray)
    
    i > j
  end
  
  def lt(i, j)
    j = j.to_na if j.is_a?(MathArray)
    
    i < j
  end
  
  def comp(other, func, return_indices=true)
    bool = send(func, @arr, other)
    if return_indices
      bool.where # indices
    else
      @arr[bool] # elements
    end
  end
  
  def to_na
    @arr
  end
  
  def index(val)
    @arr.eq(val).where[0]
  end
  
  def whiten
    mu = @arr.mean
    s = self.stddev_samp
    if s.zero?
      @arr - mu
    else
      (@arr - mu) / s
    end
  end
  
  def lgamma
    MathArray.new(@arr.collect{|i| Math.lgamma(i).first})
  end
  
  def exp
    MathArray.new(NMath.exp(@arr))
  end
  
  def method_missing(method, *args, &block)
    args = args.collect{|i| i.is_a?(MathArray) ? i.to_na : i}
    result = @arr.send(method, *args, &block)
    if result.is_a?(NArray)
      MathArray.new(result)
    else
      result
    end
  end
end