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
plot = true
d = Changepoints::DetectChangepoints.new(ts)
d.detectors = ["ControlChart", "SimplestDetector", "Cusum", "Ssr", "BayesDetector", "RecentChange"]
d.run({:plot => plot})
d.plot_changepoints if plot
puts "results #{d.results.inspect}"
````

Optional threshold value for the confidence of the changepoints returned. The default value is 0 which returns all possible changepoints. The confidences have a minimum of 0 but no maximum, however most changepoints have a confidence between 0 and 1. 

``` ruby
data = [1,2,1,2,2,1,1,1,1,2,2,2,2,1,1,1,1,1,1,1,5,5,5,5,5,5,5,5,5,5,5,5,5,5]
c = Changepoints::DetectChangepoints.new(data, threshold=0.2)
d.detectors = ["ControlChart", "SimplestDetector", "Cusum", "Ssr", "BayesDetector", "RecentChange"]
d.run
puts "results #{c.results.inspect}"
````