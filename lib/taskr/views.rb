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

# need auto_validation off to render non-XHTML XML
Markaby::Builder.set(:auto_validation, false)
Markaby::Builder.set(:indent, 2)

module Taskr::Views
  module XML
    include Taskr::Models
    
    CONTENT_TYPE = 'text/xml'
    
    def tasks_list
      @tasks.to_xml(:root => 'tasks', :include => [:task_actions])
    end
    
    def view_task
      @task.to_xml(:root => 'task', :include => [:task_actions])
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
        
        p{a(:href => self/'tasks/new') {"Schedule New Task"}}
        
        table do
          thead do
            tr do
              th "Name"
              th "Schedule"
              th "Last Triggered"
              th "Job ID"
              th "Created On"
              th "Created By"
            end
          end
          tbody do
            @tasks.each do |t|
              tr do
                td {a(:href => self/"tasks/#{t.id}") {strong{t.name}}}
                td "#{t.schedule_method} #{t.schedule_when}"
                td "#{distance_of_time_in_words(t.last_triggered, Time.now, true) if t.last_triggered} ago"
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
      script(:type => 'text/javascript') do
        %{
          function show_action_parameters(num) {
            new Ajax.Updater('parameters_'+num, '/actions', {
                method: 'get',
                parameters: { 
                  id: $F('action_class_name_'+num), 
                  action: 'parameters_form',
                  num: num
                }
            });
          }
        }
      end
      
      
      html_scaffold do
        form :method => 'post', :action => "/tasks?format=#{@format}" do
          h1 "New Task"
          input :type => 'hidden', :name => '_method', :value => 'post'
          
          p do
            label 'name' 
            br
            input :type => 'text', :name => 'name', :size => 40
          end
          
          p do
            label 'schedule'
            br
            select(:name => 'schedule_method') do
              ['every','at','in','cron'].each do |method|
                option(:value => method) {method}
              end
            end
            input :type => 'text', :name => 'schedule_when', :size => 15
          end
          
          action_form
          
          p do
            a(:id => 'add_action', :href => '#'){'Add another action'}
          end
          script(:type => 'text/javascript') do
            %{
              Event.observe('add_action', 'click', function() {
                new Ajax.Updater('add_action', '/actions', {
                    method: 'get',
                    parameters: { action: 'new', num: $$('select.action_class_name').size() },
                    insertion: Insertion.Before
                });
                return false;
              })
            }
          end
          
          button(:type => 'submit') {"submit"}
        end
      end
    end
    
    def view_task
      html_scaffold do
        form(:method => 'delete', :style => 'display: inline') do
          button(:type => 'submit', :value => 'delete') {"Delete"}
        end
        br
        a(:href => '/tasks') {"Back to Task List"}
        
        h1 "Task #{@task.id}"
        table do
          tr do
            th "Name:"
            td @task.name
          end
          tr do
            th "Schedule:"
            td "#{@task.schedule_method} #{@task.schedule_when}"
          end
          tr do
            th "Triggered:"
            td do
              if @task.last_triggered
                span "#{distance_of_time_in_words(@task.last_triggered, Time.now, true)} ago"
                span(:style => 'font-size: 8pt; color: #bbb'){"(#{@task.last_triggered})"}
              else
                em "Not yet triggered"
              end
            end 
          end
          tr do
            th "Actions:"
            td do 
              if @task.task_actions.length > 1
                ol(:style => 'padding-left: 20px') do
                  @task.task_actions.each do |ta|
                    html_task_action_li(ta)
                  end
                end
              else
                html_task_action_li(@task.task_actions.first)
              end
            end
          end
          tr do
            th "Created By:"
            td @task.created_by
          end
          tr do
            th "Created On:"
            td @task.created_on
          end
        end
      end
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
      @num ||= 0
      
      @action.parameters.each do |param|
        p do
          label param
          br
          input :type => 'textarea', :name => "action[#{@num}][#{param}]", :size => 40
        end
      end
    end
    
    def action_form
      @num ||= 0
      
      p do
        label 'action_class_name'
        br
        select(:name => "action[#{@num}][action_class_name]", 
            :id => "action_class_name_#{@num}", 
            :class => "action_class_name",
            :onchange => "show_action_parameters(#{@num})") do
          option(:value => "")
          @actions.each do |a|
            a.to_s =~ /Taskr::Actions::([^:]*?)$/
            option(:value => $~[1]) {$~[1]}
          end
        end
      end
    
      div(:id => "parameters_#{@num}")
      
    end
   
  end
  
  default_format :HTML
end