require 'java'

require "#{File.dirname(__FILE__)}/jcommon-1.0.17.jar"
require "#{File.dirname(__FILE__)}/jfreechart-1.0.14.jar"

class GenericPlot
  java_import 'org.jfree.chart.ChartUtilities'
  java_import 'org.jfree.chart.JFreeChart'
  java_import "org.jfree.chart.ChartPanel"
  java_import 'org.jfree.chart.axis.NumberAxis'
  java_import 'org.jfree.chart.plot.XYPlot'
  java_import 'org.jfree.chart.renderer.xy.StandardXYItemRenderer'
  java_import 'org.jfree.data.xy.XYSeries'
  java_import 'org.jfree.data.xy.XYSeriesCollection'
  java_import 'org.jfree.chart.plot.PlotOrientation'
  java_import "javax.swing.JFrame"
  java_import "java.awt.BorderLayout"
  java_import "org.jfree.chart.plot.ValueMarker"
  java_import "java.awt.Color"
  java_import "org.jfree.ui.ApplicationFrame"
  java_import "org.jfree.ui.RectangleAnchor"
  java_import "org.jfree.ui.RefineryUtilities"
  java_import "org.jfree.ui.TextAnchor"
  
  def self.plot(title, data, changepoints=[], verticals=[], extra_data=[])
    dataset = XYSeriesCollection.new
    
    series = XYSeries.new(title)
    data.each_with_index do |d, i|
      series.add(i, d)
    end
    dataset.addSeries(series)

    extra_data.each do |e|
      extra_series = XYSeries.new(e[:name])
      e[:data].each_with_index do |d, i|
        extra_series.add(i, d)
      end
      dataset.addSeries(extra_series)
    end
    
    x = NumberAxis.new
    y = NumberAxis.new
    
    plot = XYPlot.new
    plot.setDataset(dataset)

    verticals.each do |e|
      extra = ValueMarker.new(e[:data])
      extra.setPaint(Color.blue)
      extra.setLabel(e[:name])
      extra.setLabelAnchor(RectangleAnchor::TOP_RIGHT)
      extra.setLabelTextAnchor(TextAnchor::BOTTOM_RIGHT)
      plot.addRangeMarker(extra)
    end

    changepoints.each do |c|
      change = ValueMarker.new(c[:location])
      change.setPaint(Color.orange)
      change.setLabel(c[:confidence].to_s)
      change.setLabelAnchor(RectangleAnchor::TOP_LEFT)
      change.setLabelTextAnchor(TextAnchor::TOP_RIGHT)
      plot.addDomainMarker(change)
    end

    plot.setDomainAxis(x)
    plot.setRangeAxis(y)
    plot.setRenderer(StandardXYItemRenderer.new(StandardXYItemRenderer::LINES))

    chart = JFreeChart.new(plot)

    frame = JFrame.new(title)
    frame.content_pane.add(panel=javax.swing.JPanel.new)
    frame.setSize(600, 400)
    panel.add(ChartPanel.new(chart))
    frame.pack
    frame.visible = true
  end
end