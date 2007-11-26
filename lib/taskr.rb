#!/usr/bin/env ruby

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

class TestIt
  include OpenWFE::Schedulable
  def trigger(trigger_args)
    puts "HEY! #{trigger_args.inspect}"
  end
end

def Taskr.create
  $LOG.info "Initializing Taskr..."
  Taskr::Models::Base.establish_connection(Taskr::Conf.database)
  Taskr::Models.create_schema
  
  $LOG.info "Starting OpenWFE Scheduler..."
  
  $scheduler = OpenWFE::Scheduler.new
  $scheduler.start
  
  tasks = Taskr::Models::Task.find(:all)
  
  $LOG.info "Scheduling #{tasks.length} persisted tasks..."
  
  tasks.each do |t|
    t.schedule! $scheduler
  end
  
  $scheduler.schedule_every('10s') do
    puts "tick"
  end
end

Taskr.start_picnic