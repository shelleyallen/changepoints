Changepoint detector
--------------------

Detects changepoints in your data using a range of methods and combining results.

* Control chart
* Moving control chart (and a recent alert version)
* Cumulative sum
* Sum of square residuals detector
* Bayes detector (See Bayesian Online Changepoint Detection - Adams & MacKay)

Has a jruby version (using ruby arrays of arrays and jfreechart for plotting) and a MRI ruby version (requiring narray, statsample and gsl and gnuplot for plotting).

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