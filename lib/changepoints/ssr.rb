module Changepoints
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
end
