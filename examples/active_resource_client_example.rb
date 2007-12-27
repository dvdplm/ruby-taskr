require 'active_resource'

# Define the proxy class
class Task < ActiveResource::Base
  self.site = 'http://taskr.example.com'
end

# Retrieve a list of all the Tasks
tasks = Task.find(:all)

# Print each Task's details for debugging
tasks.each {|t| puts t.inspect}

# Retrieve a specific Task
task = Task.find(123)

# Print the Task's name
puts task.name

# Create a new Task with two actions to be executed every 10 seconds
task = Task.new
task.name = "My Example Task"
task.schedule_method = 'every'
task.schedule_when = '10s'
task.actions = [
    {:action_class_name => 'Ruby', :code => "puts 'Sending message through Howlr...'"},
    {:action_class_name => 'Howlr',
      :subject => "Testing Howlr",
      :body => "Just testing! Please ignore this.",
      :from => "joe@example.foo",
      :recipients => "sally@example.foo; bob@example.foo",
      :url => "http://howlr.example.foo/messages.xml",
      :username => 'howlr',
      :password => 'howl!'}
  ]
  
# Save the new Task; saving the Task commits it to the Taskr server
# and schedules it for execution.
task.save

# Delete the Task we just created
task.destroy

# Or delete a Task with some arbitrary id
id = 123
Task.delete(id)
