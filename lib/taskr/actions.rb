require 'openwfe/util/scheduler'
require 'active_resource'


unless $LOG
  $LOG = Logger.new(STDERR)
  $LOG.level = Logger::ERROR
end

module Taskr
  module Actions
    
    class Base
      include OpenWFE::Schedulable
      
      class_inheritable_array :parameters
      class_inheritable_accessor :description
      
      attr_accessor :parameters
      attr_accessor :task
      
      def initialize(parameters)
        self.parameters = HashWithIndifferentAccess.new(parameters)
      end
      
      def execute
        raise NotImplementedError, "Implement me!"
      end
      
      def trigger(trigger_args = {})
        puts trigger_args.inspect
        begin
          execute
        rescue => e
          puts e.inspect
          raise e
        end
      end
    end
    
    class Shell < Base
      parameters = ['command', 'user']
      description = "Execute a shell command (be careful!)"
      
      def execute
        if parameters.kind_of? Hash
          user = parameters['user']
          cmd = parameters['command']
        else
          user = nil
        end
        
        if user
          `sudo -u #{user} #{cmd}`
        else
          `#{cmd}`
        end
        
        unless $?.success?
          raise "Shell command failed (#{$?}): #{cmd}"
        end
      end
    end
    
    class Ruby < Base
      parameters = ['code']
      description = "Execute some Ruby code."
      
      def execute
        code = parameters['code']
        eval code
      end
    end
    
    class ActiveResource < Base
      parameters = ['site', 'resource', 'action', 'parameters']
      description = "Perform a REST call on a remote service using ActiveResource."
      
      def execute
        $LOG.debug self
        ::ActiveResource::Base.logger = $LOG
        ::ActiveResource::Base.logger.progname = (task ? task.to_s : self)
        
        eval %{
          class Proxy < ::ActiveResource::Base
            self.site = "#{parameters['site']}"
            self.collection_name = "#{parameters['resource'].pluralize}"
          end
        }
        
        begin
          case parameters['action']
          when 'create'
            obj = Proxy.new(parameters['parameters'])
            obj.save
          when 'update', "'update' action is not implemented"
            raise NotImplementedError
          when 'delete'
            Proxy.delete(parameters['parameters'])
          when 'find'
            raise NotImplementedError, "'find' action is not implemented"
          else
            raise ArgumentError, "unknown action #{parameters['action'].inspect}"
          end
        rescue ::ActiveResource::ServerError => e
          $LOG.error #{self} ERROR: #{e.methods.inspect}"
          raise e
        end
      end
    end
  
    class Howlr < ActiveResource
      parameters = ['site', 'from', 'recipients', 'subject', 'body']
      description = "Send a message through a Howlr service."
      
      def execute
        parameters['action'] = 'create'
        parameters['resource'] = 'message'
        parameters['parameters'] = {
          'from' => parameters['from'],
          'recipients' => parameters['recipients'],
          'subject' => parameters['subject'],
          'body' => parameters['body']
        }
        
        super
      end
    end
  
  end
end