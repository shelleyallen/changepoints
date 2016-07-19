require 'test/unit'
require_relative '../lib/changepoints'

class ChangepointsTest < Test::Unit::TestCase
  def setup
    @data = [1,2,1,2,2,1,1,1,1,2,2,2,2,1,1,1,1,1,1,1,5,5,5,5,5,5,5,5,5,5,5,5,5,5]
    @outlier_data = [1,2,1,2,2,1,1,1,1,2,2,2,2,1,1,1,1,1,1,1,6,2,2,1,1,1,1,1,1,1]
    @no_change_data = [1,2,1,2,2,1,1,1,1,2,2,2,2,1,1,1,1,1,1,1,1,1,2,2,2,2,1,1,1,1,1,1,1]
  end
  
  def test_readme
    data = NArray[*NArray.float(20).random!(1), *(NArray.float(20).random!(1)+1), *(NArray.float(20).random!(1)+2)]
    d = Changepoints::DetectChangepoints.new(data)
    d.detectors = ["ControlChart", "SimplestDetector", "Cusum", "Ssr", "BayesDetector"]
    d.run
    results = d.results
  end
  
  def test_finding_changepoints
    d = Changepoints::DetectChangepoints.new(@data)
    d.detectors = ["ControlChart", "SimplestDetector", "Cusum", "Ssr", "BayesDetector"]
    d.run
    results = d.results
    assert_equal results.length, 1
    assert_equal d.changepoints, [19]
  end
  
  def test_changepoints_high_threshold
    d = Changepoints::DetectChangepoints.new(@data, threshold=3.0)
    d.detectors = ["ControlChart", "SimplestDetector", "Cusum", "Ssr", "BayesDetector"]
    d.run
    results = d.results
    assert results.empty?
    
    e = Changepoints::DetectChangepoints.new(@data, threshold=2)
    e.detectors = ["ControlChart", "SimplestDetector", "Cusum", "Ssr", "BayesDetector"]
    e.run
    results = e.results
    assert !results.empty?
    assert_equal e.changepoints, [19]
  end
  
  def test_control_chart
    d = Changepoints::DetectChangepoints.new(@outlier_data)
    d.detectors = ["ControlChart"]
    d.run
    indices = d.changepoints
    assert_equal 20, indices[0]
  end
  
  def test_control_chart_no_change
    d = Changepoints::DetectChangepoints.new(@no_change_data)
    d.detectors = ["ControlChart"]
    d.run
    indices = d.changepoints
    assert indices.empty?
  end
  
  def test_simplest_detector
    d = Changepoints::DetectChangepoints.new(@data)
    d.detectors = ["SimplestDetector"]
    d.run
    indices = d.changepoints
    assert_equal 20, indices[0]
  end
  
  def test_simplest_detector_no_change
    d = Changepoints::DetectChangepoints.new(@no_change_data)
    d.detectors = ["SimplestDetector"]
    d.run    
    indices = d.changepoints
    assert indices.empty?
  end
  
  def test_cusum_no_change
    d = Changepoints::DetectChangepoints.new(@no_change_data)
    d.detectors = ["Cusum"]
    d.run
    indices = d.changepoints
    assert indices.empty?
  end
  
  def test_ssr_detector_no_change
    d = Changepoints::DetectChangepoints.new(@no_change_data)
    d.detectors = ["Ssr"]
    d.run
    indices = d.changepoints
    assert indices.empty?
  end
  
  def test_bayes_no_change
    d = Changepoints::DetectChangepoints.new(@no_change_data)
    d.detectors = ["BayesDetector"]
    d.run
    indices = d.changepoints
    assert indices.empty?
  end
  
  def test_bayes
    d = Changepoints::DetectChangepoints.new(@data)
    d.detectors = ["BayesDetector"]
    d.run
    indices = d.changepoints
    assert_equal [20], indices
  end
  
  def test_collapse_changepoints
    d = Changepoints::DetectChangepoints.new(@data)
    changepoints = d.squeeze_points([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.4, 0.8, 0.2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.3], 0)
    assert_equal [20, 40], changepoints
  end
  
  def test_collapse_changepoints_nonoverlapping
    d = Changepoints::DetectChangepoints.new(@data)
    changepoints = d.squeeze_points([0.4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.2], 0)
    assert_equal [0, 20, 40], changepoints
  end
  
  def test_scale_confidences
    delta = 0.00001
    d = Changepoints::DetectChangepoints.new(@data)
    old_confidences = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.4, 0.8, 0.2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.2]
    confidences = d.scale_confidences(old_confidences)
    assert confidences[19] > old_confidences[19]
    assert confidences[20] > old_confidences[20]
    assert confidences[21] > old_confidences[21]
    assert (confidences[40] < (old_confidences[40] + delta)) and (confidences[40] > (old_confidences[40] - delta))
  end
  
  def test_scale_confidences_not_local
    delta = 0.00001
    d = Changepoints::DetectChangepoints.new(@data)
    old_confidences = [0.4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.2]
    confidences = d.scale_confidences(old_confidences)
    assert (confidences[0] < (old_confidences[0] + delta)) and (confidences[0] > (old_confidences[0] - delta))
    assert (confidences[20] < (old_confidences[20] + delta)) and (confidences[20] > (old_confidences[20] - delta))
    assert (confidences[40] < (old_confidences[40] + delta)) and (confidences[40] > (old_confidences[40] - delta))
  end
end