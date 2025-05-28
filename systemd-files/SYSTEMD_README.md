# Systemd Unit and Timer Files

Timer and unit files for **snapraid-daily**. Note that only the
timer file needs to be enabled. The service file should not be
enabled as the services are not intended to be ran on startup,
but rather via the timer files alone.

Note the package installation will install all of these files
into **/etc/systemd/system/** by default. If installing manually
copy the timer and service file desired into **/etc/systemd/system/**
manually.

# snapraid-daily.service and snapraid-daily.timer

These are for running the default configuration of touch, sync
and then scrub.

# snapraid-sync.service and snapraid-sync.timer

These are for using **snapraid-daily** with the \--sync-only
argument to run a sync only and not a scrub.

Recommend enabling and running **snapraid-scrub** below if
using this timer.

# snapraid-scrub.service and snapraid-scrub.timer

These are for using **snapraid-daily** with the \--scrub-only
argument to run a scrub only and not a sync. 

Recommended to enable the **snapraid-sync** timer above if using
this one.

# Enabling the Timers

**NOTE:** Before attempting to use these service and timer files
one should verify that the script runs if called directly from
the command line from the user that will execute the script.

The next step then would be to test the service runs on its own
before enabling the timer with the following (if wanting to run
the default of sync and scrub)
```bash
sudo systemctl start snapraid-daily.service
```

Once the script runs standalone and when called by the service file
the next step is to start and enable the timer.
```bash
sudo systemctl start snapraid-daily.timer
sudo systemctl enable snapraid-daily.timer
```

# Errors

If any errors are encountered when using systemd, one can use the
following to debug them:
```bash
sudo journalctl -u snapraid-daily.service --since today
```

# Changing the Timer Files

If one wants to change the times which the timers are called, the best
thing to do is edit the **.timer** file directly in the authors experience.

For new package installations, one will be prompted to replace them if
there is a change, just take care to select "N" when upgrading using the
new package. This is obviously not an issue if installing manually.

# Editing the Service Files

If one wants to change some settings in the service files, they also can
be edited directly, and this is probably advisable for the ExecStart setting
etc. but it is more elegant to use drop-in files if possible instead,
see below for an example:     

# Running as a Non-Root User via Systemd

Note that by default all of the above service files will run as root.
This is probably fine for most users, however if one wants to run
snapraid as a different user other than root, some further configuration
is required, namely:

* Create a directory **/etc/systemd/snapraid-.service.d/**    
* Create a file called **user.conf**, or (anything**.conf**)    
* Put the following into that file and place it in the above directory    

```bash
[Service]  
User=username   
Group=groupname
```

Where **username** and **groupname** are the user and group names of the
user one wants to run snapraid, and thus **snapraid-daily** as.

The naming of the **/etc/systemd/system/snapraid-.service.d/** directory
will cause it to be picked up by all of the systemd service unit files
installed by the script, or any services with a name of the structure:     
**snapraid-\[something\].service**

Lastly, reload systemd:     
```bash
sudo systemctl daemon-reload
```

Further example drop-in files and unit files for systemd and some
notes are included here:      
https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-drop-ins    
https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-examples       

# See Also

* systemd.unit(1)   
* systemd.timer(1)   
* systemd-analyze(1)   

