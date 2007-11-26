require 'rubygems'

# make things backwards-compatible for rubygems < 0.9.0
unless Object.method_defined? :gem
  alias gem require_gem
end

require '/home/URBACON/mzukowski/workspace/picnic/lib/picnic.rb'
require 'camping'
require 'camping/db'

#gem 'reststop'
require '~/workspace/reststop/lib/reststop'

gem 'openwferu-scheduler', '~> 0.9.16'
require 'openwfe/util/scheduler'
