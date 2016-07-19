if RUBY_PLATFORM == 'java'
  require "#{File.dirname(__FILE__)}/math_array"
  require "#{File.dirname(__FILE__)}/generic_plot"
else
  require "#{File.dirname(__FILE__)}/narray_math_array"
  require "#{File.dirname(__FILE__)}/gnuplot_generic_plot"
end

module Changepoints
  DELTA = 0.0000001

  module Utils
    def weights_hash(changepoints, weight)
      results = {}
      changepoints.each do |changepoint|
        results[changepoint] = weight
      end
      results
    end

    # Choose max index for each run of near consecutive points that exceed threshold 
    # eg. For width = 2 & threshold = 0.4, [0.1, 0.5, 0.3, 0.4, 0.6, 0.1, 0.1, 0.1, 0.9] -> [4,8]
    def squeeze_points(a, threshold, width = 3)
      index        = 0
      current      = -1
      counter      = 0
      changepoints = []
    
      until a[index].nil?
        if a[index] > threshold 
          current = index if (current == -1 or a[index] > a[current])
          counter = 0
        end
    
        if counter >= width or a[index + 1].nil?
          changepoints << current if current != -1
          counter = 0
          current = -1
        end
        
        counter += 1 if current != -1
        index   += 1
      end
    
      changepoints
    end
  end
  
  class ControlChart
    include Utils
    
    def initialize(data)
      @data = MathArray.new(data)
      @n = @data.length
      @weight = 0.1
      @control_limit = 3
    end
    
    def perform
      mu = @data.mean
      s3 = @data.stddev_pop * @control_limit
      
      @up = mu + s3
      @down = mu - s3
      
      up_inds = @data.comp(@up + DELTA, "gt")
      down_inds = @data.comp(@down - DELTA, "lt")
      
      weights_hash(up_inds.to_a | down_inds.to_a, @weight)
    end
    
    def plot
      GenericPlot.plot("Control chart", @data, {}, [{:name => "UP", :data => @up}, {:name => "DOWN", :data => @down}])
    end
  end
  
  class SimplestDetector
    include Utils

    def initialize(data, control_limit=3)
      @data = MathArray.new(data)
      @n = @data.length
      @weight = 0.1
      @control_limit = control_limit
    end
    
    def perform    
      @up = MathArray.new(@n, 0)
      @down = MathArray.new(@n, 0)
      
      0.upto(@n-1) do |i|
        mu = @data[0..i].mean
        s3 = @control_limit * @data[0..i].stddev_pop
      
        @up[i] = mu + s3
        @down[i] = mu - s3
      end

      up_inds = @data.comp(@up + DELTA, "gt")
      down_inds = @data.comp(@down - DELTA, "lt")
      
      weights_hash(up_inds.to_a | down_inds.to_a, @weight)
    end
    
    def plot
      GenericPlot.plot("Simplest detector", @data, {}, [], [{:name => "UP", :data => @up.to_a}, {:name => "DOWN", :data => @down.to_a}])
    end
  end
  
  class Cusum
    include Utils

    def initialize(data)
      @data = MathArray.new(data)
      @n = @data.length
      @weight = 0.2
      @threshold = 0.2
    end
    
    def perform
      mu = @data.mean
    
      @csum = MathArray.new(@n, 0)
      @csum[0] = @data[0] - mu
      1.upto(@n-1) do |i|
        @csum[i] = @csum[i-1] + (@data[i] - @data.mean)
      end
      res = @csum/@n
      @csum = res.abs
      
      results = {}
      squeeze_points(@csum.to_a, @threshold).each do |c|
        results[c] = @weight + @csum[c] - @threshold
      end
      results
    end
    
    def plot
      GenericPlot.plot("CSUM norm", @csum, {}, [{:name => "threshold", :data => @threshold}])
    end
  end
  
  class Ssr
    include Utils

    def initialize(data)
      @data = MathArray.new(data)
      @n = @data.length
      @weight = 0.2
      @threshold = 0.2
    end
    
    def perform
      ssr_all = ((@data - @data.mean) ** 2).sum

      ssr = MathArray.new(@n-1, 0)
      0.upto(@n-2) do |k|
        x1 = @data[0..k]
        x2 = @data[(k+1)..-1]
        ssr[k] = ((x1 - x1.mean) ** 2).sum + ((x2 - x2.mean) ** 2).sum
      end
      @diff = ((-ssr.abs) + ssr_all)/(@n - 1)

      results = {}
      squeeze_points(@diff.to_a, @threshold).each do |c|
        results[c] = @weight + @diff[c] - @threshold
      end
      results
    end
    
    def plot
      GenericPlot.plot("SSR Diff", @diff, {}, [{:name => "threshold", :data => @threshold}])
    end
  end
  
  class BayesDetector
    include Utils

    def initialize(data)
      @data = MathArray.new(data)
      @n = @data.length
      @weight = 0.5
      @threshold = 0.1
    end
    
    def perform
      hazard_func = lambda{|p| MathArray.new(p, 1/200.0)}

      r = MathArray.new_2d(@n+1, @n+1, 0.0)
      r.set(0, 0, 1)

      mu0 = 0.0
      kappa0 = 1.0
      alpha0 = 1.0
      beta0 = 1.0
      muT = MathArray.new([mu0])
      kappaT = MathArray.new([kappa0])
      alphaT = MathArray.new([alpha0])
      betaT = MathArray.new([beta0])

      @changepoint_sums = MathArray.new(@n, 0)
      0.upto(@n-1) do |t|
        predprobs = studentpdf(@data[t], muT, betaT*(kappaT+1)/(alphaT*kappaT), alphaT*2)

        h = hazard_func.call(t+1)

        r.set(1..t+1, t+1, r.get(0..t,t) * predprobs * ((-h)+1))
        r.set(0, t+1, (r.get(0..t,t) * predprobs * h).sum)
        r.set(0..t+1, t+1, r.get(0..t+1,t+1) / r.get(0..t+1, t+1).sum)# Normalise

        muT0 = MathArray.new([mu0, *((kappaT * muT + @data[t]) / (kappaT+1))])
        kappaT0 = MathArray.new([kappa0, *(kappaT + 1)])
        alphaT0 = MathArray.new([alpha0, *(alphaT + 0.5)])
        betaT0 = MathArray.new([beta0, *(betaT + (kappaT * ((-muT) + @data[t]) ** 2) /((kappaT+1)*2))])
        muT = muT0
        kappaT = kappaT0
        alphaT = alphaT0
        betaT = betaT0
        
        @changepoint_sums[0..t] += r.get(0..t,t).reverse
      end
      @changepoint_sums /= MathArray.new((1..@n).to_a.reverse)

      results = {}
      squeeze_points(@changepoint_sums.to_a, @threshold)[1..-1].each do |c|
        results[c] = @weight + @changepoint_sums[c] - @threshold
      end
      results
    end
    
    def studentpdf(x, mu, var, nu)
      c = ((nu/2 + 0.5).lgamma - (nu/2).lgamma).exp * ((nu * Math::PI * var)**(-0.5))
      nu_var = (nu*var)**(-1) # 1/(nu*var)
      x_mu = ((-mu) + x)**2 # (x - mu)**2

      c * ((nu_var * x_mu) + 1)**(-(nu+1)/2)
    end
    
    def plot
      GenericPlot.plot("Bayesian", @changepoint_sums[1..-1], {}, [{:name => "threshold", :data => @threshold}])
    end
  end
  
  class RecentChange
    def initialize(data)
      @n = data.length
      @recent_n = [@n,28].min
      @data = MathArray.new(data[-@recent_n..-1]) # Just look at the last month
      @weight = 0.5
    end
    
    def perform
      @d = SimplestDetector.new(@data, 2.5)
      results = {}
      @d.perform.each do |k, w|
        location = k + (@n - @recent_n)
        results[location] = @weight if location > (@n - 7) # Only add if in last week
      end
      results
    end
    
    def plot
      @d.plot
    end
  end
  
  class DetectChangepoints
    include Utils
    
    attr_accessor :original_data, :data, :n, :results, :changepoints, :confidences, :changes, :detectors
  
    def initialize(data, threshold=0.0)
      @original_data = data
      @data = MathArray.new(@original_data)
      @data = @data.whiten
      @detectors = []
      @n = @data.length
      @threshold = threshold
    end
    
    def run(opts={})
      potential_changepoints = Array.new(@data.length, 0.0)
      @detectors.each do |detector|
        d = Changepoints.const_get(detector).new(@data)
        results = d.perform
        results.each do |idx, weight|
          potential_changepoints[idx] += weight
        end
        d.plot if opts[:plot]
      end
      scaled_confidences = scale_confidences(MathArray.new(potential_changepoints))
      @changepoints = squeeze_points(scaled_confidences, @threshold)
      @confidences = @changepoints.collect{|i| scaled_confidences[i]}
      @changes = mean_level_changes(@changepoints)

      @results = []
      0.upto(@changepoints.length - 1) do |idx|
        @results << {:location => @changepoints[idx], :confidence => @confidences[idx], :mean_level_change => @changes[idx].round(2)}
      end
    end
    
    def plot_changepoints
      GenericPlot.plot("Timeseries", @data, @results)
    end
    
    def add(class_name)
      @detectors << class_name
    end
    
    # Scale confidence of a changepoint if there are changepoints close by
    def scale_confidences(changepoints)
      inds = MathArray.new((0..(changepoints.length-1)).to_a)      
      scaled_confidences = Array.new(changepoints.length, 0)
      0.upto(changepoints.length-1) do |i|
        if changepoints[i] > 0.0
          mu = i.to_f
          y = normpdf(inds, mu, 1)
          y /= y.max
          scaled_confidences[i] = (y*changepoints).sum
        end
      end
      scaled_confidences
    end
    
    def normpdf(x, mu, sigma)
      u = (x-mu)/sigma.abs
      (-u*u/2).exp * (1.0/(Math.sqrt(2*Math::PI)*sigma.abs))
    end
  
    def change(prev, this, nxt)
      range = @data.max - @data.min
    
      before_mean = @data[prev..this].mean
      after_mean = @data[this..nxt].mean
      change = after_mean - before_mean
      100*change/range.to_f
    end
  
    def mean_level_changes(possible_changepoints)
      changes = []
    
      changepoints = possible_changepoints.to_a
      changepoints.each_with_index do |changepoint, idx|
        prev = idx == 0 ? 0 : changepoints[idx-1]
        this = changepoints[idx]
        nxt = idx == (changepoints.length - 1) ? @data.length - 1 : changepoints[idx+1]
    
        changes << change(prev, this, nxt)
      end
    
      changes
    end
  end
end