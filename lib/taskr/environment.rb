# This file is part of Taskr.
#
# Taskr is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Taskr is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Taskr.  If not, see <http://www.gnu.org/licenses/>.

$: << File.dirname(File.expand_path(__FILE__))

# Try to load local versions of Picnic and Reststop if possible...
$: << File.dirname(File.expand_path(__FILE__))+"/../../../picnic/lib"
$: << File.dirname(File.expand_path(__FILE__))+"/../../vendor/picnic/lib"
$: << File.dirname(File.expand_path(__FILE__))+"/../../../reststop/lib"
$: << File.dirname(File.expand_path(__FILE__))+"/../../vendor/reststop/lib"

# active_resource needs newer versions of active_support, but this conflicts
# with active_record, so we need a newer version of that as well (yes, it's a mess) 
$: << File.dirname(File.expand_path(__FILE__))+"/../../vendor/activeresource/lib"
$: << File.dirname(File.expand_path(__FILE__))+"/../../vendor/activesupport/lib"
$: << File.dirname(File.expand_path(__FILE__))+"/../../vendor/activerecord/lib"
require 'active_support'
require 'active_resource'
require 'active_record'

require 'rubygems'

# make things backwards-compatible for rubygems < 0.9.0
unless Object.method_defined? :gem
  alias gem require_gem
end

require 'picnic.rb'
require 'camping/db'

require 'reststop'

gem 'openwferu-scheduler', '~> 0.9.16'
require 'openwfe/util/scheduler'
