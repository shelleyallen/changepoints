module Changepoints
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
end
