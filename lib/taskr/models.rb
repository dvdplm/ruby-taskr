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

require 'camping/db'
require 'openwfe/util/scheduler'
require 'date'

class OpenWFE::Scheduler
  public :duration_to_f
end


module Taskr::Models

  class Task < Base
    has_many :task_actions, 
      :include => :action_parameters, 
      :dependent => :destroy
    
    serialize :schedule_options
    
    validates_presence_of :schedule_method
    validates_presence_of :schedule_when
    validates_presence_of :name
    validates_uniqueness_of :name
    validates_presence_of :task_actions
    validates_associated :task_actions
    
    def schedule!(scheduler)
      case schedule_method
      when 'cron'
        method = :schedule
      when 'at'
        method = :schedule_at
      when 'in'
        method = :schedule_in
      when 'every'
        method = :schedule_every
      end
      
      if method == :schedule_at || method == :schedule_in
        t = next_trigger_time
        if t < Time.now
          $LOG.warn "Task #{name.inspect} will not be scheduled because its trigger time is in the past (#{t.inspect})."
          return nil
        end
      end
      
      $LOG.debug "Scheduling task #{name.inspect}: #{self.inspect}"
      
      if task_actions.length == 1
        ta = task_actions.first
        
        parameters = {}
        ta.action_parameters.each{|p| parameters[p.name] = p.value}
        
        action = (ta.action_class.kind_of?(Class) ? ta.action_class : ta.action_class.constantize).new(parameters)
        action.task = self
      elsif task_actions.length > 1
        action = Taskr::Actions::Multi.new
        task_actions.each do |ta|
          parameters = {}
          ta.action_parameters.each{|p| parameters[p.name] = p.value}
          
          a = (ta.action_class.kind_of?(Class) ? ta.action_class : ta.action_class.constantize).new(parameters)
          a.task = self
          
          action.actions << a 
        end
        action.task = self
      else
        $LOG.warn "Task #{name.inspect} has no actions and as a result will not be scheduled!"
        return false
      end
      
      job_id = scheduler.send(method, t || schedule_when, :schedulable => action)
      
      if job_id
        $LOG.debug "Task #{name.inspect} scheduled with job id #{job_id}"
      else
        $LOG.error "Task #{name.inspect} was NOT scheduled!"
        return nil
      end
      
      self.update_attribute(:scheduler_job_id, job_id)
      if method == :schedule_at || method == :schedule_in
        job = scheduler.get_job(job_id)
        at = job.schedule_info
        self.update_attribute(:schedule_when, at)
        self.update_attribute(:schedule_method, 'at')
      end
      
      return job_id
    end
    
    def next_trigger_time
      # TODO: need to figure out how to calulate trigger_time for these.. for now return :unknown
      return :unknown unless schedule_method == 'at' || schedule_method == 'in'
          
      if schedule_method == 'in'
        return (created_on || Time.now) + Taskr.scheduler.duration_to_f(schedule_when)
      end
      
      # Time parsing code from Rails
      time_hash = Date._parse(schedule_when)
      time_hash[:sec_fraction] = ((time_hash[:sec_fraction].to_f % 1) * 1_000_000).to_i
      time_array = time_hash.values_at(:year, :mon, :mday, :hour, :min, :sec, :sec_fraction)
      # treat 0000-00-00 00:00:00 as nil
      Time.send(Base.default_timezone, *time_array) rescue DateTime.new(*time_array[0..5]) rescue nil
    end
    
    def to_s
      "#<#{self.class}:#{self.id}>"
    end
  end
  
  class TaskAction < Base
    belongs_to :task
    
    has_many :action_parameters, 
      :class_name => 'TaskActionParameter', 
      :foreign_key => :task_action_id,
      :dependent => :destroy
    
    validates_associated :action_parameters
    
    def action_class=(class_name)
      if class_name.kind_of? Class
        self[:action_class_name] = class_name.to_s
      else
        self[:action_class_name] = class_name
      end
    end
    
    def action_class
      self[:action_class_name].constantize
    end
    
    def to_xml(options = {})
      options[:indent] ||= 2
      xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
      xml.instruct! unless options[:skip_instruct]
      xml.tag!('task-action', :type => self.class) do
        xml.tag!('id', {:type => 'integer'}, id)
        xml.tag!('action-class-name', action_class_name)
        xml.tag!('order', {:type => 'integer'}, order) unless order.blank?
        xml.tag!('task-id', {:type => 'integer'}, task_id)
        xml.tag!('action-parameters', {:type => 'array'}) do
          action_parameters.each {|ap| ap.to_xml(options)}
        end
      end
    end
    
    def to_s
      "#<#{self.class}:#{self.id}>"
    end
  end

  class TaskActionParameter < Base
    belongs_to :task_action
    serialize :value
    
    def to_xml(options = {})
      options[:indent] ||= 2
      xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
      xml.instruct! unless options[:skip_instruct]
      xml.tag!('action-parameter', :type => self.class) do
        xml.tag!('id', {:type => 'integer'}, id)
        xml.tag!('name', name)
        xml.tag!('value') do
          xml.cdata!(value)
        end
      end
    end
    
    def to_s
      "#<#{self.class}:#{self.id}>"
    end
  end

  class CreateTaskr < V 0.1
    def self.up
      $LOG.info("Migrating database")
      
      create_table :taskr_tasks, :force => true do |t|
        t.column :name, :string, :null => false
        t.column :created_on, :timestamp, :null => false
        t.column :created_by, :string
        
        t.column :schedule_method, :string, :null => false
        t.column :schedule_when, :string, :null => false
        t.column :schedule_options, :text
        
        t.column :scheduler_job_id, :integer
        t.column :last_triggered, :datetime
      end
      
      add_index :taskr_tasks, [:name], :unique => true
      
      create_table :taskr_task_actions, :force => true do |t|
        t.column :task_id, :integer, :null => false
        t.column :action_class_name, :string, :null => false
        t.column :order, :integer
      end
      
      add_index :taskr_task_actions, [:task_id]
      
      create_table :taskr_task_action_parameters, :force => true do |t|
        t.column :task_action_id, :integer, :null => false
        t.column :name, :string, :null => false
        t.column :value, :text
      end
      
      add_index :taskr_task_action_parameters, [:task_action_id]
      add_index :taskr_task_action_parameters, [:task_action_id, :name]
    end
    
    def self.down
      drop_table :taskr_task_action_parameters
      drop_table :taskr_tasks
    end
  end
end