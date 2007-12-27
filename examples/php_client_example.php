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
  If your Taskr server is configured to require authentication, uncomment the next block
  and change the username and password to whatever you have in your server's config.yml.
 **/
//$username = 'taskr';
//$password = 'task!';
//Zend_Rest_Client::getHttpClient()->setAuth($username, $password);

/**
  Initialize the REST client.
 **/
$rest = new Zend_Rest_Client($taskr_site_url);

/**
  Retreiving the list of all scheduled Tasks
 **/

$tasks = $rest->get("/tasks.xml");

// $tasks is a SimpleXml object, so calling print_r($result) will let
// you see all of its data. 
//
// Here's an example of how to print out all of the tasks as an HTML list:
if ($tasks->task) {
	echo "<ul>\n";
	foreach ($tasks->task as $task) {
		echo "\t<li>".$task->name."</li>\n";
		echo "\t<ul>\n";
		echo "\t\t<li>execute ".$task->{'schedule-method'}." ".$task->{'schedule-when'}."</li>\n";
		echo "\t\t<li>created by ".$task->{'created-by'}." on ".$task->{'created-on'}."</li>\n";
		echo "\t</ul>\n";
	}
	echo "</ul>\n";
} else {
	echo "<p>There are no scheduled tasks.</p>\n";
}


/**
  Creating a new task, to be executed every 10 seconds
 **/

$data = array(
	'name' => "My Example Task #".mktime(),
	'schedule_method' => "every",
	'schedule_when' => "10s",
	'action' => array(
		'action_class_name' => "Ruby",
		'code' => 'puts "Hello World!"'
	)
);

$task1 = $rest->post('/tasks.xml', $data);

/**
  Creating a new task with multiple actions, to be executed 5 minutes from now
 **/

$data = array(
	'name' => "Another Example Task #".mktime(),
	'schedule_method' => "in",
	'schedule_when' => "5m",
	'actions' => array(
		array('action_class_name' => "Ruby",
			'code' => 'puts "Hello"'),
		array('action_class_name' => "Ruby",
			'code' => 'puts "Goodbye"')
	)
);

$task2 = $rest->post('/tasks.xml', $data);


/**
  Retreiving a specific task by its ID
 **/

$id = $task1->id;
$task = $rest->get("/tasks/$id.xml");

if ($task) {
	// print the Task's name
	echo $task->name;
	// print the type of the first action in this task
	//echo $task->{'task-actions'}->{'task-action'}[0]->{'action-class-name'};
} else {
	echo "";
}


/**
  Deleting the tasks we just created
**/
print_r($task1);
$id1 = $task1->id;
$rest->delete("/tasks/$id1.xml");

$id2 = $task2->id;
$rest->delete("/tasks/$id2.xml");


?>
