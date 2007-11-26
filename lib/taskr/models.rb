require 'camping/db'
require 'openwfe/util/scheduler'

module Taskr::Models

  class Task < Base
    has_many :action_parameters, :class_name => 'TaskActionParameter', :foreign_key => :task_id
    
    serialize :schedule_options
    
    validates_uniqueness_of :name
    
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
      
      $LOG.debug "Scheduling task #{name.inspect}: #{self.inspect}"
      
      parameters = {}
      action_parameters.each{|p| parameters[p.name] = p.value}
      
      action = (action_class.kind_of?(Class) ? action_class : action_class.constantize).new(parameters)
      
      job_id = scheduler.send(method, schedule_when, :schedulable => action)
      
      $LOG.debug "Task #{name.inspect} scheduled with job id #{job_id}"
  
      self.update_attribute(:scheduler_job_id, job_id)
      
      return job_id
    end
    
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
  end

  class TaskActionParameter < Base
    belongs_to :task
    serialize :value
  end

  class CreateTaskr < V 0.1
    def self.up
      $LOG.info("Migrating database")
      
      create_table :taskr_tasks, :force => true do |t|
        t.column :name, :string, :null => false
        t.column :created_on, :timestamp, :null => false
        t.column :created_by, :string
        
        t.column :scheduler_job_id, :integer
        t.column :schedule_method, :string, :null => false
        t.column :schedule_when, :string, :null => false
        t.column :schedule_options, :text
        
        t.column :action_class_name, :string, :null => false
      end
      
      add_index :taskr_tasks, [:name], :unique => true
      
      create_table :taskr_task_action_parameters, :force => true do |t|
        t.column :task_id, :integer, :null => false
        t.column :name, :string, :null => false
        t.column :value, :text
      end
      
      add_index :taskr_task_action_parameters, [:task_id]
      add_index :taskr_task_action_parameters, [:task_id, :name]
    end
    
    def self.down
      drop_table :taskr_task_action_parameters
      drop_table :taskr_tasks
    end
  end
end