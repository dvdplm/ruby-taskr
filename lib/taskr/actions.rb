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

require 'rufus/scheduler'

#require 'active_resource'
require 'restr'


unless $LOG
  $LOG = Logger.new(STDERR)
  $LOG.level = Logger::ERROR
end

module Taskr
  module Actions
    
    def self.list
      actions = []
      Taskr::Actions.constants.each do |m| 
        a = Taskr::Actions.const_get(m)
        actions << a if a < Taskr::Actions::Base
      end
      return actions
    end
    
    # The base class for all Actions.
    # Extend this to define your own custom Action.
    class Base
      include Rufus::Schedulable
      
      class_inheritable_accessor :parameters
      class_inheritable_accessor :description
      
      attr_accessor :parameters
      attr_accessor :task
      attr_accessor :task_action
      
      def initialize(parameters)
        self.parameters = HashWithIndifferentAccess.new(parameters)
      end
      
      def execute
        raise NotImplementedError, "Implement me!"
      end
      
      def trigger(trigger_args = {})
        begin
          $LOG.info("Executing task #{self.task.name.inspect}")
          execute
          task.update_attribute(:last_triggered, Time.now)
          task.update_attribute(:last_triggered_error, nil)
        rescue => e
          puts
          $LOG.error("Error while executing task #{self.task.name.inspect}! The error was: #{e}  (see Taskr log for debugging details)")
          $LOG.debug(e.backtrace.join($/))
          details = e.message
          details += "\n\n#{$LAST_ERROR_BODY}" if $LAST_ERROR_BODY # dumb way of reading Restr errors... Restr needs to be fixed
          task.update_attribute(:last_triggered, Time.now)
          task.update_attribute(:last_triggered_error, {:type => e.class.to_s, :message => details})
          raise e
        end
      end
      
      def to_s
        "#{self.class.name}(#{parameters.inspect})"
      end
    end
    
    # Do not extend this class. It is used internally to schedule multiple
    # actions per task. 
    #
    # If you want to define your own custom Action, extend Taskr::Actions::Base
    class Multi
      include Rufus::Schedulable
      
      attr_accessor :actions
      attr_accessor :task
      
      def initialize
        self.actions = []
      end
      
      def trigger(trigger_args = {})
        begin
          $LOG.info("Executing task #{self.task.name.inspect}")
          actions.each do |a|
            a.execute
            LogEntry.info(a, "Action #{a} executed.")
          end
          # TODO: maybe we should store last_triggered time on a per-action basis?
          task.update_attribute(:last_triggered, Time.now)
          task.update_attribute(:last_triggered_error, nil)
        rescue => e
          $LOG.error("Error while executing task #{self.task.name.inspect}! The error was: #{e} (see Taskr log for debugging details)")
          $LOG.debug("#{e.backtrace}")
          task.update_attribute(:last_triggered, Time.now)
          task.update_attribute(:last_triggered_error, {:type => e.class.to_s, :details => "#{e.message}"})
          # FIXME: Maybe actions should be responseible for logging their errors, otherwise we double-log the same error.
          LogEntry.error(task, "Task #{task} raised an exception: \n#{e.class}: #{e.message}\n#{e.backtrace}")
          raise e
        end
      end
    end
    
    class RotateTaskLog < Base
      self.parameters = ['delete_old_log_entries_after_days']
      self.description = "Deletes old task log entries from this Taskr server's database."
      
      def execute
        num = parameters['delete_old_log_entries_after_days'].to_i
        
        cond = ['timestamp < ?', Time.now - num.days]
        LogEntry.delete_all(cond)
        LogEntry.debug(task_action, "Deleted log entries with conditions: #{cond.inspect}")
      end
    end
    
    class Shell < Base
      self.parameters = ['command', 'as_user']
      self.description = "Execute a shell command (be careful!)"
      
      def execute
        if parameters.kind_of? Hash
          user = parameters['as_user']
          cmd = parameters['command']
        else
          user = nil
        end
        
        unless user.blank?
          cmd = "sudo -u #{user} #{cmd}"
        end
        
        outio = StringIO.new
        errio = StringIO.new
        old_stdout, $stdout = $stdout, outio
        old_stderr, $stderr = $stderr, errio
        
        out = `#{cmd}`
        
        err = errio.string
        out = outio.string
        LogEntry.debug(task_action, out) unless out.blank?
        LogEntry.error(task_action, err) unless err.blank?
        
        $stdout = old_stdout
        $stderr = old_stderr
        
        unless $?.success?
          msg = "Shell command #{cmd.inspect} failed (returned code #{$?}): #{out}"
          LogEntry.error(task_action, msg)
          raise msg
        end
      end
    end
    
    class Ruby < Base
      self.parameters = ['code']
      self.description = "Execute some Ruby code."
      
      def execute
        outio = StringIO.new
        errio = StringIO.new
        old_stdout, $stdout = $stdout, outio
        old_stderr, $stderr = $stderr, errio
        
        code = parameters['code']
        eval(code)
        
        err = errio.string
        out = outio.string
        LogEntry.debug(task_action, out) unless out.blank?
        LogEntry.error(task_action, err) unless err.blank?
        
        $stdout = old_stdout
        $stderr = old_stderr
      end
    end


# This is too complicated... we use Restr instead.
#    class ActiveResource < Base
#      self.parameters = ['site', 'resource', 'action', 'parameters']
#      self.description = "Perform a REST call on a remote service using ActiveResource."
#      
#      def execute
#        $LOG.debug self
#        ::ActiveResource::Base.logger = $LOG
#        ::ActiveResource::Base.logger.progname = (task ? task.to_s : self)
#        
#        eval %{
#          class Proxy < ::ActiveResource::Base
#            self.site = "#{parameters['site']}"
#            self.collection_name = "#{parameters['resource'].pluralize}"
#          end
#        }
#        
#        begin
#          case parameters['action']
#          when 'create'
#            obj = Proxy.new(parameters['parameters'])
#            obj.save
#          when 'update', "'update' action is not implemented"
#            raise NotImplementedError
#          when 'delete'
#            Proxy.delete(parameters['parameters'])
#          when 'find'
#            raise NotImplementedError, "'find' action is not implemented"
#          else
#            raise ArgumentError, "unknown action #{parameters['action'].inspect}"
#          end
#        rescue ::ActiveResource::ServerError => e
#          $LOG.error #{self} ERROR: #{e.methods.inspect}"
#          raise e
#        end
#      end
#    end
#  
#    class Howlr < ActiveResource
#      self.parameters = ['site', 'from', 'recipients', 'subject', 'body']
#      self.description = "Send a message through a Howlr service."
#      
#      def execute
#        parameters['action'] = 'create'
#        parameters['resource'] = 'message'
#        parameters['parameters'] = {
#          'from' => parameters['from'],
#          'recipients' => parameters['recipients'],
#          'subject' => parameters['subject'],
#          'body' => parameters['body']
#        }
#        
#        super
#      end
#    end
  
    class Rest < Base
      self.parameters = ['method', 'url', 'params', 'username', 'password']
      self.description = "Perform a REST call on a remote service."
      
      def execute
        auth = nil
        if parameters['username']
          auth = {}
          auth['username'] = parameters['username'] if parameters['username']
          auth['password'] = parameters['password'] if parameters['password']
        end
        
        if parameters['params'].kind_of? String
          params2 = {}
          parameters['params'].split('&').collect do |p|
            key, value = p.split('=')
            params2[key] = value
          end
          parameters['params'] = params2
        end
        
        Restr.logger = LogEntry.logger_for_action(task_action)
        Restr.do(parameters['method'], parameters['url'], (parameters['params'] unless parameters['params'].blank?), auth)
      end
    end
    
    class Howlr < Rest
      self.parameters = ['url', 'from', 'recipients', 'subject', 'body', 'username', 'password', 'content_type']
      self.description = "Send a message through a Howlr service."
      
      def execute
        content_type = parameters['content_type']
        content_type = 'text/plain' if content_type.blank?
        
        parameters['method'] = 'post'
        parameters['params'] = {
          'content_type' => content_type,
          'from' => parameters['from'],
          'recipients' => parameters['recipients'],
          'subject' => parameters['subject'],
          'body' => parameters['body'],
          'format' => 'XML'
        }
        
        super
      end
    end
    
    class Taskr4rails < Base
      self.parameters = ['url', 'auth', 'ruby_code', 'dont_wait']#, 'shell_command']
      self.description = "Executes code on a remote Rails server via the taskr4rails plugin."
      
      def execute
        data = {
          :task_name => task.name,
          :task_id => task.id,
          :auth => parameters['auth'],
          :ruby_code => parameters['ruby_code']#,
          #:shell_command => parameters['shell_command']
        }
        
        
        Restr.logger = LogEntry.logger_for_action(task_action)
        Restr.post(parameters['url'], data)
      end
    end
  end
end