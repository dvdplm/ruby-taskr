module Taskr::Controllers
  
  class Test < R '/test'
    def get
      require 'taskr/actions'
      
      @tasks = Task.find(:all)
      
      @actions = Taskr::Actions.list
      
      render :test
    end
    
    def post
      render :action_parameters
    end
  end
  
  class Actions < REST 'actions'
    def list
      @actions = Taskr::Actions.list
      
      render :action_list
    end
    
    def form(id)
      @action = Taskr::Actions.list.find {|a| a.to_s =~ Regexp.new("#{id}$")}
      if @action
        render :action_parameters_form
      else
        @status = 404
        "Action #{id.inspect} not defined"
      end
    end
  end
  
  class Tasks < REST 'tasks'
    include Taskr::Models
    
    def list
      @tasks = Task.find(:all)
      
      render :tasks_list
    end
    
    def new
      @actions = Taskr::Actions.list
      
      render :new_task
    end
    
    def read(id)
      @task = Task.find(id)
      
      render :view_task
    end
    
    def create
      action_class_name = @input[:action_class_name]
      action_class_name = "Taskr::Actions::#{action_class_name}" unless action_class_name =~ /^Taskr::Actions::/
      
      begin
        action_class = action_class_name.constantize
        unless action_class.include? OpenWFE::Schedulable
          raise ArgumentError, 
            "#{@input[:action_class_name].inspect} cannot be used as an action because it does not include the OpenWFE::Schedulable module."
        end
      rescue NameError
        raise ArgumentError, 
          "#{@input[:action_class_name].inspect} is not defined (i.e. there is no such action class)."
      end
      
      name            = @input[:name]
      created_by      = @env['REMOTE-HOST']
      schedule_method = @input[:schedule_method]
      schedule_when   = @input[:schedule_when]
      
      @task = Task.new(
        :name => name,
        :created_by => created_by,
        :schedule_method => schedule_method,
        :schedule_when => schedule_when,
        :action_class => action_class
      )
      
      parameters = @input[:parameters] || {}
      parameters.each do |k,v|
        p = TaskActionParameter.new(:name => k, :value => v)
        @task.action_parameters << p
      end
      
      unless @task.valid?
        @status = 500
        return render(:new_task)
      end
      
      @task.schedule! $scheduler
      
      if @task.save
        @headers['Location'] = "/tasks.xml/#{@task.id}"
      end
      
      return redirect(self/'tasks')
    end
    
    def destroy(id)
      @task = Task.find(id)
      $scheduler.unschedule(@task.scheduler_job_id) if @task.scheduler_job_id
      @task.destroy
      return redirect(self/'/')
    end
  end
end