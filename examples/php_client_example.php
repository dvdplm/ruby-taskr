<?php

/**
  To use this exmple, you will need the Zend Framework from:

      http://framework.zend.com/download

  For more information on using the Zendr_Rest_Client, see:

      - http://framework.zend.com/manual/en/zend.rest.client.html
      - http://www.pixelated-dreams.com/archives/243-Next-Generation-REST-Web-Services-Client.html
**/

require 'Zend/Rest/Client.php';

$taskr_site_url = "http://localhost:7007";



/**
  Retreiving the list of all scheduled Tasks
 **/

$rest = new Zend_Rest_Client($taskr_site_url);
$tasks = $rest->get("/tasks.xml");

// $tasks is a SimpleXml object, so calling print_r($result) will let
// you see all of its data. 
//
// Here's an example of how to print out all of the tasks as an HTML list:

echo "<ul>";
foreach ($tasks->task as $task) {
	echo "<li>".$task->name."</li>";
	echo "<ul>";
	echo "<li>execute ".$task->{'schedule-method'}." ".$task->{'schedule-when'}."</li>";
	echo "<li>created by ".$task->{'created-by'}." on ".$task->{'created-on'}."</li>";
}
echo "</ul>";



/**
  Retreiving a specific task
 **/

$id = 6;
$rest = new Zend_Rest_Client($taskr_site_url);
$task = $rest->get("/tasks/$id.xml");

// print the Task's name
echo $task->name;
// print the type of the first action in this task
echo $task->{'task-actions'}->{'task-action'}[0]->{'action-class-name'};


/**
  Creating a new task, to be executed every 10 seconds
 **/

$data = array(
	'name' => "My Example Task",
	'schedule_method' => "every",
	'schedule_when' => "10s",
	'actions' => array(
		array('action_class_name' => "Ruby",
			'code' => 'puts "Hello World!"'),
		array('action_class_name' => "Ruby",
			'code' => 'puts "Goodbye!"')
	)
);

$rest = new Zend_Rest_Client($taskr_site_url);
$rest->post('/tasks.xml', $data);


/**
  Deleting a task
**/

$id = 6;
$rest = new Zend_Rest_Client($taskr_site_url);
$task = $rest->delete("/tasks/$id.xml");
 
?>
