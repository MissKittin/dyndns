#!/bin/bash
#####################
### Bash DDNS client
### PHP DDNS server
### 17.01.2019
### Patch 03.09.2019
### wget params correction 22.09.2019
#####################

# Settings
host='http://your.domain/dyndns/'
user='updateusername'
password='updatepassword'
sleep_time='900' # seconds
log_file='/tmp/.ddns_client.log'

# Functions
loga()
{
	echo -n "$@" >> $log_file
}
logb()
{
	echo "$@" >> $log_file
}

# Log daemon start
logb " DDNS client started `date +%d.%m.%Y` `date +%H:%M`"

# Loop
while true; do
	# Refresh ip, time, date and reset flag
	ip=`wget -4 -q -O- http://ipinfo.io/ip`
	time=`date +%H:%M`
	date=`date +%d.%m.%Y`
	failed=false

	# Check if ip correct
	if [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		# Check if ip changed - prevent from web host denial
		if [ "$last_ip" = "$ip" ] && [ ! "$last_ip" = 'failed' ]; then
			# Log
			logb "Not updating, IP $ip not changed at $date $time"
		else
			# Send data to server
			loga "Updating ddns $ip $date $time "
			result=`wget -4 -q -O- "${host}?user=${user}&password=${password}&ip=${ip}&time=${time}&date=${date}"`

			# Log results
			if [ "$?" = 0 ]; then
				loga 'OK '
			else
				loga 'Network failed '
				failed=true
			fi
			if [ "$result" = 'OK' ]; then
				logb 'OK'
			else
				logb 'PHP failed'
				failed=true
			fi

			# Save actual ip
			$failed && last_ip=failed || last_ip=$ip
		fi
	else
		logb "IP address mailformed at $date $time"
		failed=true
	fi

	# Wait for next update
	$failed && sleep 10 || sleep $sleep_time
done

# Prevent executing script below
exit 0


# .htaccess for apache - deny access to *.txt files
<FilesMatch ".txt">
    Order Allow,Deny
    Deny from All
</FilesMatch>


<?php
	// PHP DDNS server
	// 17.01.2019

	/* Usage: sent arguments in GET form
	For Bash DDNS client:
		user=username -> your username in client settings
		password=set_password -> your password in client settings
	For view:
		user=view_username -> string in $view_user
		password=view_password -> string in $view_password
		notime=1 -> print only ip number */
	

	// Settings - for set part
	$set_user='updateusername';
	$set_password='updatepassword';

	// Settings - for view part
	$view_user='username';
	$view_password='password';

	// Check if username and password exists in variables
	if(isset($_GET['user']) && isset($_GET['password']))
	{
		// Set part - save data from client
		if($_GET['user'] === $set_user && $_GET['password'] === $set_password)
		{
			// Save data to files
			file_put_contents('ip.txt', $_GET['ip']);
			file_put_contents('date.txt', $_GET['date'] . ' ' . $_GET['time']);

			// Send confirmation to client
			echo 'OK';

			// Done
			exit();
		}

		// View part - print saved data
		if($_GET['user'] === $view_user && $_GET['password'] === $view_password)
		{
			// Check if client want pure ip number
			if(isset($_GET['notime']))
			{
				// Read file
				echo file_get_contents('ip.txt');
			}
			else
			{
				// Read files
				echo file_get_contents('ip.txt');
				echo '<br>';
				echo file_get_contents('date.txt');
			}

			// Done
			exit();
		}
	}
?>
<!-- You can write page here -->