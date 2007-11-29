module Taskr::Controllers
  
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
      @task = Task.find(id, :include => [:task_actions])
      
      render :view_task
    end
    
    def create
      begin
        puts @input.class
        puts @input.to_xml if @input.kind_of?(XmlSimple)
        puts @input.inspect
        
        task_data = @input[:task] || @input
          
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
        
        if task_data[:actions]
          if task_data[:actions].kind_of?(Array)
            actions = task_data[:actions]
          else
            actions = task_data[:actions][:action]
          end
        elsif task_data[:action]
          actions = task_data[:action]
        else
          raise ArgumentError, "Missing action(s) parameter."
        end
        
        actions = [actions] unless actions.kind_of? Array
        puts actions.inspect
        
        i = 0
        actions.each do |a|
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
          
          parameters = a[:parameters] || {}
          
          parameters.each do |k,v|
            action.action_parameters << TaskActionParameter.new(:name => k, :value => v)
          end
          
          @task.task_actions << action
          i += 1
        end
        
        
        unless @task.valid?
          @status = 500
          return render(:new_task)
        end
      
        
        @task.schedule! $scheduler
        
        if @task.save
          @headers['Location'] = "/tasks.xml/#{@task.id}"
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
      $scheduler.unschedule(@task.scheduler_job_id) if @task.scheduler_job_id
      @task.destroy
      return redirect('/tasks')
    end
  end
end