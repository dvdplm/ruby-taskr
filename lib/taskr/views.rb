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
      html_scaffold do
        h1 {"Tasks"}
        
        a(:href => self/'tasks/new') {"Schedule New Task"}
        
        table do
          thead do
            tr do
              th "Name"
              th "Action"
              th "When"
              th "Job ID"
              th "Created On"
              th "Created By"
            end
          end
          tbody do
            @tasks.each do |t|
              tr do
                td {a(:href => self/"tasks/#{t.id}") {t.name}}
                td t.action_class_name
                td "#{t.schedule_method} #{t.schedule_when}"
                td t.scheduler_job_id
                td t.created_on
                td t.created_by
              end
            end
          end
        end
      end
    end
    
    def new_task
      form :method => 'post', :action => '/tasks' do
        html_scaffold do
          h1 "New Task"
          input :type => 'hidden', :name => '_method', :value => 'post'
          
          p do
            label 'name' 
            br
            input :type => 'text', :name => 'name', :size => 40
          end
          
          p do
            label 'schedule_method'
            br
            input :type => 'text', :name => 'schedule_method', :size => 40
          end
          
          p do
            label 'schedule_when'
            br
            input :type => 'text', :name => 'schedule_when', :size => 40
          end
          
          p do
            label 'action_class_name'
            br
            select(:type => 'text', :name => 'action_class_name', :id => 'action_class_name') do
              option(:value => "")
              @actions.each do |a|
                a.to_s =~ /Taskr::Actions::([^:]*?)$/
                option(:value => $~[1]) {$~[1]}
              end
            end
          end
        
          div(:id => 'parameters')
          script(:type => 'text/javascript') do
            %{
              Event.observe('action_class_name', 'change', function() {
                new Ajax.Updater('parameters', '/actions', {
                    method: 'get',
                    parameters: { id: $F('action_class_name'), action: 'form' }
                });
              })
            }
          end
          
          button(:type => 'submit') {"submit"}
        end
      end
    end
    
    def view_task
      form(:method => 'delete', :style => 'display: inline') do
        button(:type => 'submit', :value => 'delete') {"Delete"}
      end
      pre @task.to_yaml
    end
    
    def action_list
      h1 "Actions"
      ul do
        @actions.each do |a|
          li a
        end
      end
    end
    
    def action_parameters_form
      puts @action.inspect
      @action.parameters.each do |param|
        p do
          label param
          br
          input :type => 'text', :name => "parameters[#{param}]", :size => 40
        end
      end
    end
    
    def test
      html_scaffold do
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
  end
  
  default_format :HTML
end