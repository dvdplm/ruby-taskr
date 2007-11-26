module Taskr::Controllers
  
  class Test < R '/test'
    def get
      @tasks = Task.find(:all)
      render :test
    end
  end
  
  class Tasks < REST 'tasks'
    include Taskr::Models
    
    def list
      @tasks = Task.find(:all)
      render :tasks_list
    end
    
    def create
      begin
        action_class = @input[:action_class_name].constantize
        unless action_class.include? OpenWFE::Schedulable
          raise ArgumentError, 
            "#{@input[:action_class_name].inspect} cannot be used as an action because it does not include the OpenWFE::Schedulable module."
        end
      rescue NameError
        raise ArgumentError, 
          "#{@input[:action_class_name].inspect} is not defined (i.e. no there is no such class)."
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
        return render(:create_task_result)
      end
      
      @task.schedule! $scheduler
      
      if @task.save
        @headers['Location'] = "/tasks.xml/#{@task.id}"
      end
      
      return render(:create_task_result)
    end
  end
end