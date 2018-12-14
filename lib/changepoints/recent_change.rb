module Changepoints
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
end
