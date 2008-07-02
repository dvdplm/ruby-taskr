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
      @tasks.to_xml(:root => 'tasks')#, :include => [:task_actions])
    end
    
    def view_task
      @task.to_xml(:root => 'task')#, :include => [:task_actions])
    end
  end
  
  module HTML
    include Taskr::Controllers
    
    CONTENT_TYPE = 'text/html'
    
    def tasks_list
      html_scaffold do
        h1 {"Tasks"}
        
        p{a(:href => R(Taskr::Controllers::Tasks, 'new')) {"Schedule New Task"}}
        
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
              tr_css = []
              tr_css << "error" if t.last_triggered_error
              tr_css << "expired" if t.next_trigger_time != :unknown && t.next_trigger_time < Time.now
              
              tr(:class => tr_css.join(" ")) do
                td {a(:href => R(t)) {strong{t.name}}}
                td "#{t.schedule_method} #{t.schedule_when}"
                td do
                  if t.last_triggered
                    "#{distance_of_time_in_words(t.last_triggered, Time.now, true)} ago"
                  else
                    em "Not yet triggered"
                  end
                end
                td(:class => "job-id") {t.scheduler_job_id}
                td t.created_on
                td t.created_by
              end
            end
          end
        end
        
        br
        div {scheduler_status}
      end
    end
    
    def new_task
      html_scaffold do
        script(:type => 'text/javascript') do
          %{
            function show_action_parameters(num) {
              new Ajax.Updater('parameters_'+num, '#{R(Actions)}', {
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
        
        form :method => 'post', :action => self/"/tasks?format=#{@format}" do
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
            input :type => 'text', :name => 'schedule_when', :size => 30
          end
          
          p do
            label 'description/memo' 
            br
            textarea(:name => 'memo', :cols => '60', :rows => '4'){""}
          end
          
          action_form
          
          p do
            a(:id => 'add_action', :href => '#'){'Add another action'}
          end
          script(:type => 'text/javascript') do
            %{
              Event.observe('add_action', 'click', function() {
                new Ajax.Updater('add_action', '#{R(Actions, :new)}', {
                    method: 'get',
                    parameters: { num: $$('select.action_class_name').size() },
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
        form(:method => 'delete', :style => 'display: inline', :action => R(@task)) do
          button(:type => 'submit', :value => 'delete', :onclick => 'return confirm("Are you sure you want to unschedule and delete this task?")') {"Delete"}
        end
        form(:method => 'put', :style => 'display: inline', :action => R(@task, 'run')) do
          button(:type => 'submit', :value => 'run') {"Run Now!"}
        end
        br
        a(:href => R(Tasks, :list)) {"Back to Task List"}
        
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
            th "Description/Memo:"
            td "#{@task.memo}"
          end
          tr do
            th "Job ID:"
            td @task.scheduler_job_id
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
          if @task.last_triggered_error
            th "Error:"
            td(:style => 'color: #e00;') do
              strong "#{@task.last_triggered_error[:type]}"
              br
              pre @task.last_triggered_error[:message]
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
        
        script %{
          function clickbold(el) {
            $$('#logfilter a').each(function(a){a.style.fontWeight = 'normal'})
            el.style.fontWeight = 'bold'
          } 
        }
        
        p(:style => "margin-top: 20px; border-top: 1px dotted black; padding-top: 10px", :id => 'logfilter') do
          strong "Show: "
          a(:href => R(LogEntries, :list, :task_id => @task.id, :since => (Time.now - 1.day).to_formatted_s(:db)),
            :target => 'log', :onclick => "clickbold(this)", :style => 'font-weight: bold') {"Last 24 Hours"}
          text "|"
          a(:href => R(LogEntries, :list, :task_id => @task.id, :since => (Time.now - 2.days).to_formatted_s(:db)),
            :target => 'log', :onclick => "clickbold(this)") {"48 Hours"}
          text "|"
          a(:href => R(LogEntries, :list, :task_id => @task.id),
            :target => 'log', :onclick => "clickbold(this)") {"All"}
        end
        iframe(:src => R(LogEntries, :list, :task_id => @task.id, :since => (Time.now - 1.day).to_formatted_s(:db)), 
                :style => 'width: 100%;', :name => 'log')
      end
    end
    
    def scheduler_status
      s = Taskr.scheduler
      h3(:style => "margin-bottom: 8px;") {"Scheduler Status"}
      strong "Running?"
      span(:style => 'margin-right: 10px') {s.instance_variable_get(:@stopped) ? "NO" : "Yes"}
      strong "Precision:"
      span(:style => 'margin-right: 10px') {"#{s.instance_variable_get(:@precision)}s"}
      strong "Pending Jobs:"
      span(:style => 'margin-right: 10px') {s.instance_variable_get(:@pending_jobs).size}
      strong "Thread Status:"
      span(:style => 'margin-right: 10px') {s.instance_variable_get(:@scheduler_thread).status}
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
      
      p {em @action.description}
      
      @action.parameters.each do |param|
        p do
          label param
          br
          input :type => 'text', :name => "action[#{@num}][#{param}]", :size => 50
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
   
    def log_entries_list
      h2 do
        "Log" +
         (@since.blank? ? "" : em(:style => "font-weight: normal; font-size: 9pt"){"Showing entries since #{@since}"})
      end
            
      table do
        @log_entries.each do |entry|
          case entry.level.downcase.intern
          when :error
            bg_color = '#faa'
          when :warn
            bg_color = '#ffa'
          when :info
            bg_color = '#aaf'
          when :debug
            bg_color = '#eee'
          else
            bg_color = '#fff; '+entry.level.inspect
          end
          tr do
            td(:style => "vertical-align: top; font-size: 9pt; white-space: nowrap; background: #{bg_color}") do
              entry.timestamp
            end
            td(:style => "vertical-align: top; font-size: 9pt; background-color: #{bg_color}; font-size: 9pt; font-family: monospace") do
              entry.data.gsub(/<\/?(html|body)>/, '').gsub(/\n/, "<br />")
            end
          end
        end
      end
    end
  end
  
  default_format :HTML
end