Changepoint detector
--------------------

Detects changepoints in your data using a range of methods and combining results.

* Control chart `[ControlChart]`. The control chart detects a change when a data point in the timeseries falls outside an upper or lower limit (3 standard deviations away from the mean).
* Moving control chart `[SimplestDetector]` (and a recent alert version `[RecentChange]`). The moving control chart is similar to the control chart but the upper and lower limit are 3 standard deviations away from a moving average of the data. This results in a more sensitive method.
* Cumulative sum `[Cusum]`. The cumulative sum method calculates the cumulative sum at each point of the difference between the data points and the mean. It then divides by the length of the timeseries and finds any points that exceed a threshold (0.2). We then choose the most recently exceeding points within sensible windows of points.
* Sum of square residuals detector `[Ssr]`. The sum of square residuals method moves through each point in the data and calculates the sum of squares for the data up to that point and the sum of squares after and sums them at each point. The overall sum of squares is minused at each point and divides by the length of the timeseries. As with the Cusum method, a changepoint is detected for the most recent point that exceeds a threshold (0.2).
* Bayes detector ([See Bayesian Online Changepoint Detection - Adams & MacKay]( https://hips.seas.harvard.edu/files/adams-changepoint-tr-2007.pdf)) `[BayesDetector]`. The Bayes detector is the most sophisticated method and most weight is given to the changes it finds. It calculates the probability distribution of a run since the last changepoint.

Has a jruby version (using ruby arrays of arrays and jfreechart for plotting) and a MRI ruby version (requiring narray, statsample and gsl and gnuplot for plotting).

The detectors array controls which changepoint detection methods are used. Each method has a weight associated with it - essentially how much we trust the changes it detects. We combine all the changes and weights found and return a final set of changepoints with associated weights.

``` ruby
ts = NArray[*NArray.float(20).random!(1), *(NArray.float(20).random!(1)+1), *(NArray.float(20).random!(1)+2)]
plot = true
d = Changepoints::DetectChangepoints.new(ts)
d.detectors = ["ControlChart", "SimplestDetector", "Cusum", "Ssr", "BayesDetector", "RecentChange"]
d.run({:plot => plot})
d.plot_changepoints if plot
puts "results #{d.results.inspect}"

%> results [{:location=>20, :confidence=>0.6216871928292554, :mean_level_change=>32.09}, {:location=>34, :confidence=>0.4037551836328037, :mean_level_change=>10.39}, {:location=>40, :confidence=>1.4970841700929944, :mean_level_change=>28.68}]
````

Optional threshold value for the confidence of the changepoints returned. The default value is 0 which returns all possible changepoints. The confidences have a minimum of 0 but no maximum, however most changepoints have a confidence between 0 and 1. 

``` ruby
data = [1,2,1,2,2,1,1,1,1,2,2,2,2,1,1,1,1,1,1,1,5,5,5,5,5,5,5,5,5,5,5,5,5,5]
c = Changepoints::DetectChangepoints.new(data, threshold=0.2)
c.detectors = ["ControlChart", "SimplestDetector", "Cusum", "Ssr", "BayesDetector", "RecentChange"]
c.run
puts "results #{c.results.inspect}"
%> results [{:location=>19, :confidence=>2.2565344518481565, :mean_level_change=>84.58}]
````
