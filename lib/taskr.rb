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
require 'taskr/environment'

Camping.goes :Taskr
Taskr.picnic!

require 'taskr/controllers'

module Taskr
end

require 'taskr/actions'
require 'taskr/models'
require 'taskr/helpers'
require 'taskr/views'
require 'taskr/controllers'

module Taskr
  include Taskr::Models
end

include Taskr::Models

def Taskr.create
  $LOG.info "Initializing Taskr..."
  Taskr::Models::Base.establish_connection(Taskr::Conf.database)
  Taskr::Models.create_schema
  
  if self::Conf[:external_actions]
    if self::Conf[:external_actions].kind_of? Array
      external_actions = self::Conf[:external_actions]
    else
      external_actions = [self::Conf[:external_actions]]
    end
    external_actions.each do |f|
      $LOG.info "Loading additional action definitions from #{self::Conf[:external_actions]}..."
      require f
    end
  end
  
  $LOG.info "Starting OpenWFE Scheduler..."
  
  $scheduler = OpenWFE::Scheduler.new
  $scheduler.start
  
  tasks = Taskr::Models::Task.find(:all)
  
  $LOG.info "Scheduling #{tasks.length} persisted tasks..."
  
  tasks.each do |t|
    t.schedule! $scheduler
  end
end

Taskr.start_picnic