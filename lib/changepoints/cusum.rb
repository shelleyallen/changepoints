module Changepoints
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
end
