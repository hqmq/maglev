# This file holds test cases that used to be in BrokenRegressions.rb, but
# have subsequently been fixed.  This file is run by vmunit.conf, so that
# we can ensure we don't regress on these ad-hoc cases.
require File.expand_path('simple', File.dirname(__FILE__))

# The Rubinius Struct.rb does this
class Foo
  class << self
    alias_method :my_new, :new
  end
end

##################################################

begin
  ary = [1,2,3]
  ary["cat"]
rescue TypeError
  # Nothing
rescue Exception => e
  puts "non TypeError unacceptable...#{e}"
end



#### From the Mspec framework

obj = Object.new
def obj.start
  @width = 12  # Blows up: No method found for the selector #'indexOfIdentical:'
end
def obj.width
  @width
end
obj.start

test(obj.width, 12, 'dynamic instvar created from singleton')

report
