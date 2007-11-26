# need auto_validation off to render non-XHTML XML
Markaby::Builder.set(:auto_validation, false)
Markaby::Builder.set(:indent, 2)

module Taskr::Views
  module XML
    include Taskr::Models
    
    CONTENT_TYPE = 'text/xml'
    
    def tasks_list
      puts @tasks.class
      @tasks.to_xml(:root => 'tasks')
    end
    
    def create_task_result
      taskr_response_xml(@task.valid? ? 'success' : 'failure') do
        text @task.to_xml
        text @task.errors.to_xml unless @task.valid?
      end
    end
  end
  
  module HTML
    CONTENT_TYPE = 'text/html'
    
    def tasks_list
      h1 {"Tasks"}
    end
    
    def create_task_result
      pre @task.to_yaml
    end
    
    def test
      hr 
      form :method => 'get', :action => '/tasks' do
        p "read"
        input :type => 'hidden', :name => '_method', :value => 'get'
        select :name => 'id' do
          @tasks.each do |t|
            option(:value => t.id) { t.name }
          end
        end
        button(:type => 'submit') {"submit"}
      end
      hr
      
      form :method => 'get', :action => '/tasks' do
        p "list"
        input :type => 'hidden', :name => '_method', :value => 'get'
        button(:type => 'submit') {"submit"}
      end
      hr
      
      form :method => 'post', :action => '/tasks' do
        p "create"
        input :type => 'hidden', :name => '_method', :value => 'post'
        
        label 'name' 
        input :type => 'text', :name => 'name', :size => 40
        br
        label 'schedule_method' 
        input :type => 'text', :name => 'schedule_method', :size => 40
        br
        label 'schedule_when' 
        input :type => 'text', :name => 'schedule_when', :size => 40
        br
        label 'action_class_name' 
        input :type => 'text', :name => 'action_class_name', :size => 40
        br
        label 'recipients'
        input :type => 'text', :name => 'parameters[recipients]', :size => 40
        br
        label 'from'
        input :type => 'text', :name => 'parameters[from]', :size => 40
        br
        label 'subject'
        input :type => 'text', :name => 'parameters[subject]', :size => 40
        br
        label 'body'
        input :type => 'textarea', :name => 'parameters[body]', :size => 40
        
        button(:type => 'submit') {"submit"}
      end
      hr
      
#      form :method => 'post', :action => '/tasks' do
#        p "destroy"
#        select :name => 'id' do
#          @tasks.each do |w|
#            option(:value => w.environment_id.wfid) { w.environment_id.wfid }
#          end
#        end
#        input :type => 'hidden', :name => '_method', :value => 'delete'
#        button(:type => 'submit') {"submit"}
#      end
#      hr
#      
#      form :method => 'post', :action => '/tasks' do
#        p "update"
#        input :type => 'hidden', :name => '_method', :value => 'put'
#        input :type => 'text', :name => 'participant'
#        input :type => 'text', :name => 'data[name]'
#        select :name => 'id' do
#          @tasks.each do |w|
#            option(:value => w.environment_id.wfid) { w.environment_id.wfid }
#          end
#        end
#        button(:type => 'submit') {"submit"}
#      end
    end
  end
  
  default_format :HTML
end