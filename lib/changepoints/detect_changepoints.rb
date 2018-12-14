module Changepoints
  class DetectChangepoints
    include Utils
    
    attr_reader :original_data, :data, :n, :results, :changepoints, :confidences, :changes, :detectors

    def initialize(data, threshold = 0.0, detectors: [])
      @original_data = data
      @data = MathArray.new(@original_data)
      @data = @data.whiten
      @detectors = detectors
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
      @results
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
      changepoints.each_with_index do |_changepoint, idx|
        prev = idx == 0 ? 0 : changepoints[idx-1]
        this = changepoints[idx]
        nxt = idx == (changepoints.length - 1) ? @data.length - 1 : changepoints[idx+1]
    
        changes << change(prev, this, nxt)
      end
    
      changes
    end
  end
end
