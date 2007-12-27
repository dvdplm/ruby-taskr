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

# Create a new Task to be executed every 10 seconds
task = Task.new
task.name = "My Example Task"
task.schedule_method = 'every'
task.schedule_when = '10s'
task.actions = [
    {:action_class_name => 'Ruby', :code => "puts 'Hello World!'"},
    {:action_class_name => 'Ruby', :code => "puts 'Goodbye!'"}
  ]
  
# Save the new Task -- the Task is not scheduled for execution until
# it is saved.
task.save

# Deleting the task we just created
id = task.id
Task.delete(id)
