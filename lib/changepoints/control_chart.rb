module Changepoints
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

      up_inds = @data.comp(@up + Utils::DELTA, "gt")
      down_inds = @data.comp(@down - Utils::DELTA, "lt")

      weights_hash(up_inds.to_a | down_inds.to_a, @weight)
    end

    def plot
      GenericPlot.plot("Control chart", @data, {}, [{:name => "UP", :data => @up}, {:name => "DOWN", :data => @down}])
    end
  end
end
