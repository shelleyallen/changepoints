module Changepoints
  module Utils
    DELTA = 0.0000001

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
end
