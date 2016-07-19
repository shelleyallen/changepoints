class MathArray < Array
  def self.new_2d(i, j, val)
    MathArray.new(i){MathArray.new(j, val)}
  end
  
  def set(i_range, j_range, v)
    if i_range.is_a?(Integer) and j_range.is_a?(Integer)
      self[i_range][j_range] = v
    elsif i_range.is_a?(Integer)
      j_range.each_with_index do |j, j_ind|
        self[i_range][j] = v[j_ind]
      end      
    elsif j_range.is_a?(Integer)
      i_range.each_with_index do |i, i_ind|
        self[i][j_range] = v[i_ind]
      end
    else
      i_range.each_with_index do |i, i_ind|
        j_range.each_with_index do |j, j_ind|
          self[i][j] = v[i_ind][j_ind]
        end
      end
    end
  end
  
  def get(i_range, j_range)
    if i_range.is_a?(Integer) and j_range.is_a?(Integer)
      self[i_range][j_range]
    elsif i_range.is_a?(Integer)
      a = MathArray.new(j_range.to_a.length)
      j_range.each_with_index do |j, j_ind|
        a[j_ind] = self[i_range][j]
      end
    elsif j_range.is_a?(Integer)
      a = MathArray.new(i_range.to_a.length)
      i_range.each_with_index do |i, i_ind|
        a[i_ind] = self[i][j_range]
      end
    else
      a = MathArray.new(i_range.to_a.length){MathArray.new(j_range.to_a.length, 0)}
      i_range.each_with_index do |i, i_ind|
        j_range.each_with_index do |j, j_ind|
          a[i_ind][j_ind] = self[i][j]
        end
      end
    end

    a
  end
  
  def sum
    s = 0
    self.each{|i| s += i}
    s
  end
  
  def mean
    self.sum/self.length.to_f
  end

  def sum_squares
    s = 0
    m = self.mean
    self.each{|i| s += (i - m)**2}
    s
  end
  
  def stddev_samp
    Math.sqrt(self.sum_squares/(self.length - 1))
  end
  
  def stddev_pop
    Math.sqrt(self.sum_squares/self.length)
  end
  
  def find_all_index
    all = MathArray.new
    self.each_with_index do |e, i|
      all << i if yield e
    end
    all
  end
  
  def +(s)
    case s
    when Numeric
      MathArray.new(self.collect{|v| v + s})
    else
      res = MathArray.new
      self.each_with_index do |e, i|
        res[i] = e + s[i]
      end
      res
    end
  end
  
  def -(s)
    case s
    when Numeric
      MathArray.new(self.collect{|v| v - s})
    else
      res = MathArray.new
      self.each_with_index do |e, i|
        res[i] = e - s[i]
      end
      res
    end
  end
  
  def /(s)
    case s
    when Numeric
      MathArray.new(self.collect{|v| v / s})
    else
      res = MathArray.new
      self.each_with_index do |e, i|
        res[i] = e / s[i]
      end
      res
    end
  end

  def *(s)
    case s
    when Numeric
      MathArray.new(self.collect{|v| v * s})
    else
      res = MathArray.new
      self.each_with_index do |e, i|
        res[i] = e * s[i]
      end
      res
    end
  end
  
  def **(s)
    case s
    when Numeric
      MathArray.new(self.collect{|v| v ** s})
    else
      res = MathArray.new
      self.each_with_index do |e, i|
        res[i] = e ** s[i]
      end
      res
    end
  end
  
  def gt(i, j)
    i > j
  end
  
  def lt(i, j)
    i < j
  end
  
  def comp(other, func, return_indices=true)
    inds = MathArray.new
    elements = MathArray.new
    
    case other
    when Numeric
      self.each_with_index do |e, i|
        if send(func, e, other)
          inds << i
          elements << e
        end
      end
    else
      self.each_with_index do |e, i|
        if send(func, e, other[i])
          inds << i
          elements << e
        end
      end
    end
    
    if return_indices
      inds
    else
      elements
    end
  end
  
  def whiten
    mu = self.mean
    s = self.stddev_samp
    if s.zero?
      self - mu
    else
      (self - mu) / s
    end
  end

  def abs
    MathArray.new(self.collect{|i| i.abs})
  end
  
  def lgamma
    MathArray.new(self.collect{|i| Math.lgamma(i).first})
  end
  
  def exp
    MathArray.new(self.collect{|i| Math.exp(i)})
  end
  
  def -@
    MathArray.new(self.collect{|i| -i})
  end
end