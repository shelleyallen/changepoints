require 'gnuplot'

class GenericPlot
  def self.plot(title, data, changepoints=[], extras=[], more=[])
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|

        plot.title  title
        plot.ylabel "data"
        plot.xlabel "date"

        plot.data << Gnuplot::DataSet.new( data.to_a ) do |ds|
          ds.with = "lines"
        end
        
        changepoints.each do |c|
          plot.data << Gnuplot::DataSet.new( [[c[:location], c[:location]], [data.min, data.max]] ) do |ds|
            ds.with = "impulses"
            ds.title = "#{c[:confidence]}"
          end
        end
        
        extras.each do |e|
          plot.data << Gnuplot::DataSet.new( [[0, data.length-1], [e[:data], e[:data]]] ) do |ds|
            ds.with = "lines"
            ds.title = "#{e[:name]}"
          end
        end
        
        more.each do |e|
          plot.data << Gnuplot::DataSet.new( e[:data] ) do |ds|
            ds.with = "lines"
            ds.title = "#{e[:name]}"
          end
        end
      end
    end
  end
end