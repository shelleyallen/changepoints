module Changepoints
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

      up_inds = @data.comp(@up + Utils::DELTA, "gt")
      down_inds = @data.comp(@down - Utils::DELTA, "lt")

      weights_hash(up_inds.to_a | down_inds.to_a, @weight)
    end

    def plot
      GenericPlot.plot("Simplest detector", @data, {}, [], [{:name => "UP", :data => @up.to_a}, {:name => "DOWN", :data => @down.to_a}])
    end
  end
end
