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

module Taskr::Controllers
  
  class ActionTypes < REST 'action_types'
    def list
      @actions = Taskr::Actions.list
      
      render :action_list
    end
  end
  
  class Actions < REST 'actions'
    def parameters_form(id)
      @num = @input[:num] || 0
      @action = Taskr::Actions.list.find {|a| a.to_s =~ Regexp.new("#{id}$")}
      if @action
        render :action_parameters_form
      else
        @status = 404
        "Action #{id.inspect} not defined"
      end
    end
    
    def new
      @num = @input[:num] || 0
      @actions = Taskr::Actions.list
      render :action_form
    end
  end
  
  class Tasks < REST 'tasks'
    include Taskr::Models
    
    def list
      @tasks = Task.find(:all, :include => [:task_actions])
      
      render :tasks_list
    end
    
    def new
      @actions = Taskr::Actions.list
      
      render :new_task
    end
    
    def read(id)
      @task = Task.find(id, :include => [:task_actions])
      
      render :view_task
    end
    
    def create
      begin
        puts @input.class
        puts @input.to_xml if @input.kind_of?(XmlSimple)
        puts @input.inspect
        
        # the "0" is for compatibility with PHP's Zend_Rest_Client
        task_data = @input[:task] || @input["0"] || @input
          
        name            = task_data[:name]
        created_by      = @env['REMOTE_HOST']
        schedule_method = task_data[:schedule_method]
        schedule_when   = task_data[:schedule_when]
        
        @task = Task.new(
          :name => name,
          :created_by => created_by,
          :schedule_method => schedule_method,
          :schedule_when => schedule_when
        )
        
        # some gymnastics here to provide compatibility for the way various
        # REST client libraries submit data
        actions_data = task_data[:actions] || task_data[:action]
        
        raise ArgumentError, "Missing action(s) parameter." if actions_data.blank?

        if actions_data.kind_of?(Array)
          actions = actions_data
        elsif actions_data["0"]
          actions = []
          actions_data.each do |i,a|
            actions << a
          end
        else
          actions = actions_data[:action] || actions_data[:actions] || actions_data
        end
        
        actions = [actions] unless actions.kind_of? Array
        puts actions.inspect
        
        i = 0
        actions.each do |a|
          puts a.inspect
          action_class_name = a[:action_class_name]
          action_class_name = "Taskr::Actions::#{action_class_name}" unless action_class_name =~ /^Taskr::Actions::/
          
          begin
            action_class = action_class_name.constantize
            unless action_class.include? OpenWFE::Schedulable
              raise ArgumentError, 
                "#{a[:action_class_name].inspect} cannot be used as an action because it does not include the OpenWFE::Schedulable module."
            end
          rescue NameError
            raise ArgumentError, 
              "#{a[:action_class_name].inspect} is not defined (i.e. there is no such action class)."
          end
          
          action = TaskAction.new(:order => a[:order] || i, :action_class_name => action_class_name)
          
          action_class.parameters.each do |p|
            action.action_parameters << TaskActionParameter.new(:name => p, :value => a[p])
          end
          
          @task.task_actions << action
          i += 1
        end
        
        
        unless @task.valid?
          @status = 500
          return render(:new_task)
        end
      
        
        @task.schedule! Taskr.scheduler
        
        if @task.save
          location = "/tasks/#{@task.id}?format=#{@format}"
          $LOG.debug "#{@task} saved successfuly. Setting Location header to #{location.inspect}."
          @headers['Location'] = location
        end
        
        return render(:view_task)
      rescue => e
        puts e.inspect
        puts e.backtrace
        raise e
      end
    end
    
    def destroy(id)
      @task = Task.find(id)
      Taskr.scheduler.unschedule(@task.scheduler_job_id) if @task.scheduler_job_id
      @task.destroy
      return redirect(R(Tasks, :list))
    end
  end
end