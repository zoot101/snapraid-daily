# SnapRAID-DAILY

Simple Bash Script to automate all essential SnapRAID functions on Linux.

In built email notifications with monitoring of the number of deletes/moves/updates.

Customisable through the use of external hooks. See some examples here:    
* https://github.com/zoot101/snapraid-daily-hooks
* Hooks are provided above for **Apprise** (which supports sending notifications to Telegram, ntfy, Discord, Slack and many more services), **Healthchecks.io**, manage a list of services with systemd, or to issue simple commands at the start and end.

# Introduction 

Thank you for your interest in this script! SnapRAID is very good software, but lacks any default automation or notification ability. That is where this script comes in,
it is intended to be an all-in-one script for the automation of all essential SnapRAID functions and do it in a simple manner.

There are other scripts out there that essentially do the same thing. However, none of them had exactly had the features the author wanted.

Some of the other scripts also enforce running them and **SnapRAID** as root. In the opinion of the author, this is not needed and best avoided if possible. This script
does not require running as root, and prompts the user during installation to automate running the script as a different user as desired. 

This led to this script being created by the author. It has worked extremely well for the author for many years up to this date, and hopefully prove useful to others,
hence the reason for publishing it here in Github. Every attempt below has also been put into making the documentation and the Readme as detailed as possible such that it is
easy to use and quick to get started with.

# Quick-Start

I've tried to make the readme here as detailed as possible, and I encourage reading it through entirely but over time it has grown in size. As nothing beats
getting something up and running quickly, below is a brief guide to get started quickly with the script.

First, ensure **SnapRAID** is functioning okay on your system - that is, you can run sync and scrub operations without errors.

To install the script, if on Debian or a Debian-based distro like Ubuntu or Mint install the provided package like so:

* Download the latest Debian package from the release page [HERE](https://github.com/zoot101/snapraid-daily/releases)
* Install it like so - all dependencies should be installed automatically. Answer the prompts for a user and group if you want to run the script as a different user other than root. If you are okay with running it as root, enter "root" at the prompts or leave them blank.
  - `sudo apt install ./snapraid-daily_1.5.0-1_amd64.deb`
* Edit the config file that was installed at **/etc/snapraid-daily.conf** to your needs. The comments included should help, check out the installed manual entry for the config file like so, or read on below. Note that the script should also run out of the box with the default config file (or with no config file), but will not send any emails.
  - `man snapraid-daily.conf`
* Call the script directly to test it out. See the [Usage](#usage) section below.
  - `snapraid-daily`
* Start the systemd-timer like so:
  - `sudo systemctl start snapraid-daily.timer`

To install the script on a non-Debian based distro, install the script manually like so:

* Download the latest "Source Code" archive from the release page [HERE](https://github.com/zoot101/snapraid-daily/releases) and extract it.
  - `unzip snapraid-daily-1.5.2.zip` or `tar xvf snapraid-daily-1.5.2.tar.gz`
  - `cd snapraid-daily-1.5.2`
* Place the main script in /usr/bin and make it executable. For Example:
  - `chmod +x snapraid-daily && sudo cp snapraid-daily /usr/bin/`
* Install the manual entries (optional)
  - `sudo cp ./manual/snapraid-daily.1.gz /usr/share/man/man1`
  - `sudo cp ./manual/snapraid-daily.conf.1.gz /usr/share/man/man1`
* Next, copy the sample config and place it in /etc, then edit it to your needs. Once again the comments included should help, check out the manual entry for the config file, or read on below. Note also that the script will run out of the box with the default config file (or with no config file) but will not send any emails. 
  - `sudo cp snapraid-daily.conf /etc`
* Call the script directly to test it out. See the [Usage](#usage) section below.
  - `snapraid-daily`
* Copy the snapraid-daily.timer and snapraid-daily.service from the systemd-files folder to **/etc/systemd/system**
  - `sudo cp ./systemd-files/snapraid-daily.timer ./systemd-files/snapraid-daily.service /etc/systemd/system` 
  - Then, see the section below [Running as a Non-Root User with Systemd](#running-as-a-standard-user-with-systemd) if you want to run the script as a different user than root. If you are okay with running it as root, this is not required. 
* Reload systemd and start the timer like so
  - `sudo systemctl daemon-reload && sudo start snapraid-daily.timer`

For detailed instructions on each step of the way or to use the more advanced features like the start/end/notification hooks, read on below.

Or, to get notifications on services like Telegram, ntfy or others, have a look at the Apprise Hook script here:

* [https://github.com/zoot101/snapraid-daily-hooks](https://github.com/zoot101/snapraid-daily-hooks)

# Table of Contents

- [Scope](#scope)
- [Description](#description)
- [Quick Start](#quick-start)
- [Usage](#usage)
  * [Examples](#examples)
- [Installation](#installation)
  * [Package Installation](#package-installation)
  * [Manual Installation](#manual-installation)
- [Setup](#setup)
  * [Config File Setup](#config-file-setup)
  * [Config File Contents](#config-file-contents)
  * [Sample Config File](#sample-config-file)
  * [Setting Up Email Notifications](#setting-up-email-notifications)
  * [Automation with Systemd](#automation-with-systemd)
  * [Running as a Non-Root User with Systemd](#running-as-a-standard-user-with-systemd)
  * [Alternative - Automation with Cron](#alternative---automation-with-cron)
  * [External Hooks](#external-hooks)
    - [Notification Hooks](#notification-hooks)
    - [Start and End Hooks](#start-and-end-hooks)
- [SnapRAID Sync and Scrub Options](#snapraid-sync-and-scrub-options)
- [Detailed Operation](#detailed-operation)
  * [Step 1 - Initial Checks](#step-1---initial-checks)
  * [Step 2 - Check SnapRAID Array Current Status](#step-2---check-snapraid-array-current-status)
  * [Step 3 - Run Start Hooks if Given](#step-3---run-start-hooks-if-given)
  * [Step 4 - Run Touch if Required](#step-4---run-touch-if-required)
  * [Step 5 - Check Array for Changes](#step-5---check-array-for-changes)
  * [Step 6 - Run Sync to Update the Array](#step-6---run-sync-to-update-the-array)
  * [Step 7 - Run Scrub to Check for Silent Corruption](#step-7---run-scrub-to-check-for-silent-corruption)
  * [Step 8 - Run End Hooks If Given](#step-8---run-end-hooks-if-given)
  * [Step 9 - Send Final Notification Email](#step-9---send-final-notification-email)
  * [Step 10 - Run Notification Hooks if Given](#step-10---run-notification-hooks-if-given)
- [Sample Output](#sample-output)
- [Further Examples](#further-examples)
- [Creating your own Debian Package](#creating-your-own-debian-package)
  - [Removing the Dependency on SnapRAID](#removing-the-dependency-on-snapraid)
- [Return Codes](#return-codes)
- [Issues](#issues)
- [Credits](#credits)

# Scope

This script is intended to focus just on **SnapRAID** and simple email notifications. This is keeping in the traditional unix philosophy of do one thing and do it well.

Additional functionality such as alternative forms of notifications are accomplished through the use of Start/End and Notification Hooks.
See the additional repo here, and the section on the hooks below.

* [https://github.com/zoot101/snapraid-daily-hooks](https://github.com/zoot101/snapraid-daily-hooks)

# Description

The script is intended to be ran as a scheduled task via Systemd Timers, but  can also easily be installed and ran manually if need be.

If errors are detected, the user is notified by email and the script will exit. **Mutt** is used for sending the emails.

Note that no attempts are made here to automate the correction of errors, the user will have to intervene in each case if they are detected.

Before attempting to use this script, one should ensure that **SnapRAID** is normally functioning. That is one can run the following commands without
any error being encountered.

```bash
snapraid status
snapraid sync
snapraid scrub 
```

See the SnapRAID documentation here:
 
* [https://www.snapraid.it](https://www.snapraid.it)

The script will run out of the box with the default config file, or with no config file. However for best operation, a config file is required.

The number of files deleted, moved, or updated are monitored and if any exceed the threshold values specified in the **snapraid-daily.conf** config file, the script
will exit and notify the user via email, and use the notification hooks if specified in the config file.

The idea here is that if a large number of accidental moves, deletions or updates are detected, it is probably an accident, and a sync would be a bad idea
as it will prevent the recovery of those files.

If errors are detected, the script will notify the user via email and attach the logfile generated by the SnapRAID command itself that generated the error,
so the user can quickly see what the problem is from the email notification alone.

Adding a quick report of Hard-Disk SMART data and spinning down Hard-Disks via SnapRAID is also supported by the script.

# Usage

```bash
Usage: snapraid-daily         [OPTIONS...]

  -s, --sync-only             Only Sync the Array - Do not run Scrub

  -c, --scrub-only            Only Scrub the Array - Do not run Sync
                              Note that if both of these options are omitted, the
                              default is to run sync and then scrub. They also can
                              not be specified at the same time

  -o, --override-thresholds   Ignore the deletion/moved thresholds to force a sync,
                              useful to quickly sync if the thresholds are exceeded,
                              but one is happy to proceed.

  -f, --config [path-to-conf] Override default config file. Could be useful if one
                              has multiple snapraid arrays to manage on the same system

  -q, --quiet                 Suppress the output of the touch, diff, sync and scrub
                              commands for snapraid. The final status message is still
                              displayed as normal.

  -h, --help                  Print help

Manual Entries:
  Main Script:                snapraid-daily(1)      $ man snapraid-daily
  Config File:                snapraid-daily.conf(1) $ man snapraid-daily.conf
```

By default if no arguments are invoked the script will execute the following functions in the below order. This will accomplish everything and is
sufficient to run once a day or however often is desired.

1. Check for Inital Errors    
2. Run Touch (If Required)    
3. Sync the array (If Changes are Present)    
4. Scrub the array

This can also be tweaked by the supported arguments to the script if one wants to sync the array only or scrub the array only.

## Examples

For default operation - Sync and then scrub do:
```bash
snapraid-daily
```

To only perform sync:  
```bash
snapraid-daily -s
```

To only perform sync and override thresholds:     
```bash
snapraid-daily -s -o
```

To only perform scrub, do:     
```bash
snapraid-daily -c
```

To override the config file to **/path/to/user.conf** do:     
```bash
snapraid-daily -f /path/to/user.conf
```

If an invalid argument is specified, the script will exit.

# Installation

There are two ways to install and use this script - via the provided Debian Package for Debian and its derivatives or manually.

## Package Installation

A package is provided for Debian and its derivatives. Note that the author has tested this most on Debian itself (Bookworm and Trixie), and
also tested it out on Linux Mint and Ubuntu. It should work on other Debian based distros ok too. The script has also been tested on Fedora via manual
installation.

Its highly recommended to use the package if one is running a Debian based distro so the dependencies are handled automatically.

To install the package download it from the releases page below and do the following. It's better to use **apt** rather than **dpkg** so the dependencies will be
automatically installed.

* [https://github.com/zoot101/snapraid-daily/releases](https://github.com/zoot101/snapraid-daily/releases)

Install the package like so:

```bash
sudo apt update
sudo apt install ./snapraid-daily_1.5.2-1_amd64.deb
```

During installation, one will be prompted for a user and group to run the script as a service via systemd.

Input your desired user and group. If you're not sure about the group, leave it blank to use the default group for the user that was input. Alternatively, one can specify
root as the user to have the script run as root, or leave the user blank to automatically select root.

If one wants to change the user and group that runs the service after the install, the following command can be issued to be prompted again.

```bash
sudo dpkg-reconfigure snapraid-daily
```

Then, move on to the Config file setup section below.

## Manual Installation

Alternatively to install manually, do the following:

First download the latest source code archive from the releases page [HERE](https://github.com/zoot101/snapraid-daily/releases) and extract it as below.
One can of course clone the whole repo with **git clone**, but there may some edits that are not fully tested in the non-released version of the script or the other config files etc.,
so its recommended to stick with what is on the releases page instead.

```bash
# Extract the Archive
unzip snapraid-daily-1.5.2.zip       # For the zip file
tar xvf snapraid-daily-1.5.2.tar.gz  # For the tar.gz file

cd snapraid-daily

# Install the main script
chmod +x snapraid-daily
sudo cp snapraid-daily /usr/bin/

# Install the sample config file to the default location
sudo cp ./config/snapraid-daily.conf /etc/

# Install the manual entries
sudo cp ./manual/snapraid-daily.1.gz /usr/share/man/man1/
sudo cp ./manual/snapraid-daily.conf.1.gz /usr/share/man/man1/

# Install the systemd unit files
sudo cp ./systemd-files/snapraid-*.service /etc/systemd/system/
sudo cp ./systemd-files/snapraid-*.timer /etc/systemd/system/

# Create a drop-in file to run the service as
# a non-root user. Can be skipped if one is happy to run the
# script as root
sudo mkdir /etc/systemd/system/snapraid-.service.d/
sudo echo "[Service]" > /etc/systemd/system/snapraid-.service.d/user.conf
sudo echo "User=your_username" >> /etc/systemd/system/snapraid-.service.d/user.conf
sudo echo "Group=your_group" >> /etc/systemd/system/snapraid-.service.d/user.conf

# Lastly - Reload Systemd
sudo systemctl daemon-reload
```

Next ensure all dependencies are installed:

* grep, awk, sed, mktemp, tee (Available on pretty much every linux based system)
* mutt
* SnapRAID (This is left up to the user and not considered here)

If on Debian, one can do:
```bash
# On Debian
sudo apt install coreutils gawk mutt snapraid

# On Fedora
sudo dnf install coreutils gawk mutt snapraid
```

# Setup

After installation, the next step is to create the config file as discussed below.

## Config File Setup

As mentioned above, the script will run out of the box without a config file, but for best operation it will require a configuration file set up.

The location for the config file **(snapraid-daily.conf)** is tried in the following order of preference:

1. Via the **-f** or **\--config option** if specified    
2. **/etc/snapraid-daily.conf**    
3. **snapraid-daily.conf** in the script directory    

If the config file is not found in any of the above locations, the defaults will be used. Note that this will disable the email functionality.

The minimum contents of **snapraid-daily.conf** should contain the following and the syntax should be correct as per bash. The script will again exit if errors
are present in this file.

1. MuttRC File Path for Notification Emails    
2. Email Address for Notification Emails    
3. Deletion Threshold    
4. Moved Threshold
5. Updated Threshold
6. Sync Pre Hash   
7. Scrub Percentage     
8. Scrub Age     

See the sample here:
* [https://github.com/zoot101/snapraid-daily/tree/main/docs/sample-config/snapraid-daily.conf](https://github.com/zoot101/snapraid-daily/tree/main/docs/sample-config/snapraid-daily.conf)

If installed via the debian package, a sample configuration file is already placed at the 1st location above (/etc/snapraid-daily.conf) that can be
edited directly by the user.

A manual entry is also provided for the config file here:
* `man snapraid-daily.conf`

As mentioned before, overriding the default config file can be accomplished by using the **-f, \--config [PATH-TO-CONFIG]** as an input argument
to the script. In this case the name of the config file does not have to be **snapraid-daily.conf**.

The debian package installation will also place a sample file that does more with the script in the docs location below.

* `/usr/share/doc/snapraid-daily/examples/snapraid-daily.conf`

This can also be used as a template to generate the optimum config file in  the default location:

* `/etc/snapraid-daily.conf`

Finally if the script cannot find any configuration file it will continue with the defaults - see the below:

## Config File Contents

The main parameters included in the file are:

* **snapraid_config_file_path**    
* **muttrc_path**    
* **email_address**    
* **deletion_threshold**    
* **moved_threshold**
* **updated_treshold**    
* **sync_pre_hash**     
* **scrub_percent**    
* **scrub_age**    

If any of the above are missing, defaults are loaded, see below:

### snapraid\_config\_file\_path

This is the path to the main config file defining the array for SnapRAID itself. It is usually **/etc/snapraid.conf** but in the event that it is at a different location, it
can be specified here. The default is **/etc/snapraid.conf**

This is useful for the situation where the user may be running multiple SnapRAID arrays on the same system, but for the vast
majority of users it'll be **/etc/snapraid.conf**.

To run with multiple SnapRAID arrays, one could create a copy of the config file (snapraid-daily.conf), change this setting and
pass it to the script with the **-f, --config** option.

### muttrc\_path

This is the path for the muttrc file that is used for sending email notifications. No emails are sent if this is omitted.
The default is empty, whereby no emails are sent.

See the notes provided in the docs directory here to set up the email
notifications.

* [https://github.com/zoot101/snapraid-daily/tree/main/docs/muttrc-examples](https://github.com/zoot101/snapraid-daily/tree/main/docs/muttrc-examples)

The following sample configs are provided along with instructions on how to set them up.

* Gmail via App Passwords   
* Outlook via Oauth2
* Gmail via Oauth2   
* Fastmail.com   
* ntfy (Self-Hosted)   

Comment out to disable email notifications. If one wants to use an alternative form of notifcation either instead of emails or in addtion
to them see the Notification Hooks section below.

### email\_address

Main email address to send the notification emails to. This can also be commented out to
disable email notifications.

### deletion\_threshold

If the number of files deleted since the last sync is found to be greater than this number, then the script
will exit and notify the user via email. Must be a postive number. The default is **100** if omitted or commented out.

On the other hand, to disable permanently and sync every time regardless of the number deleted, set to 0.

### moved\_threshold

As above, but for files moved. Must be a positive number. The default is **100** if omitted or commented out. As before, to disable permanently and
sync every time regardless of the number moved, set to 0.

### updated\_threshold

Also as above, but for files updated. Must be a positive number. Set to zero to disable permanently and sync each time regardless of the number
of updated files. If omitted or commented out, the default is **100**.

### sync\_pre\_hash

Allows disabling of the use of the "-h" or "--pre-hash" option for SnapRAID during sync operations. This will speed up sync operations but forfeit the
added safeguard that the extra preliminary hash operation provided. Set to **no** to disable. On by default if omitted. It is recommended to leave it
on.

### scrub\_percent

The percentage of the array to scrub - should be a number between 1 and 100. The default is **8** (or 8%).

### scrub\_age

The age of files in days to scrub. Should be a standard posive number. The default is **21** (or 21 days).

## Additional Options

A number of additional options are provided to address some potential edge cases. None of these are required to be specified and can be omitted.

### disable\_emails\_on\_success

Disable the notification emails on successful runs. It is the preference of the author to always have emails sent on success
so one always knows the script is running and doing its job without explicity checking it.

Note that this does not effect any emails sent to notify the user about an error during sync/touch/scrub or exceeded thresholds,
those are still sent as normal.

Set to \"yes\" to use, leave commented out or set to \"no\" to disable. Note that if one is using the notification hooks
(see below), they are also disabled on successful runs if this option is used, but still called when errors are encountered.

### force\_zero

By default during **sync**, if SnapRAID encounters a file of zero size that was not previously of zero size, it will report this as
an error and exit the sync. This is possible to happen during a system crash in Linux systems, so is **NOT RECOMMENDED** to use. This option
causes SnapRAID to continue to sync anyway in this condition.

Set to \"yes\" to use, leave commented out or set to \"no\" to disable.

### force\_empty

If one or more of the disks are found to now be empty whereby in the past they were not, SnapRAID will report this as an error and
stop the sync. This is **NOT RECOMMENDED** to use, but is included for certain edge conditions that may require it. This option causes
SnapRAID to continue to sync anyway in this condition.

Set to \"yes\" to use, leave commented out or set to \"no\" to
disable.

### force\_uuid

If the UUID of one or more disks is found to change, usually SnapRAID will report this as an error and stop the sync. This option causes
SnapRAID to continue to sync anyway in this condition. This is also **NOT RECOMMENDED** to use, but is again included for certain edge conditions
that may require it.

Set to \"yes\" to use, leave commented out or set to \"no\" to
disable.

### snapraid\_binary\_path

This option is for cases where the **SnapRAID** binary is installed in a different location than the default. The vast majority of users should
not need to use this.

If, for example **SnapRAID** itself is installed from outside the offical repos or compiled from source, the main binary may not be in the users
**PATH**. If this is the case, an alternative path to the **SnapRAID** binary can be specified here. Uncomment and set the path to the alternative
location of the binary if required.

By default if this option is not used, the output of the command **which snapraid** is used to get the path to the **SnapRAID** binary.

### disable\_update\_check

By default, the script will check if curl is installed, and if so will check
the Github page to see if a new updated version is available. It does this by looking at
the following file which stores the currently released version number.

* [https://raw.githubusercontent.com/zoot101/snapraid-daily/refs/heads/main/VERSION](https://raw.githubusercontent.com/zoot101/snapraid-daily/refs/heads/main/VERSION) 

If an updated version is found, it will print out a note saying so
to the email that is sent when the script completes. An example is shown below:

```
##############################
# SnapRAID-DAILY Version: 1.5.3
##############################
# Update Available at https://github.com/zoot101/snapraid-daily/releases
##############################
Initialized at 15:09:12 on 19/10/2025
 * Hostname: nas.example.org
 * Host OS: Debian GNU/Linux 13 (trixie)
 * SnapRAID Version: 12.4 
```

Comment out and set to yes if you wish to disable this feature.

### smart\_report

Get SnapRAID to generate its SMART report and add it to the email. This calls "snapraid smart" and records its output in the email
notification that is sent. This either requires the script to be ran as root or for sudo to be set up to call **snapraid smart** as a 
non-root user. A sample output in the notification email looks like this:

```
##############################
# SnapRAID-DAILY: SMART Report
##############################
SnapRAID SMART report:

   Temp  Power   Error   FP Size
      C OnDays   Count        TB  Serial           Device    Disk
 -----------------------------------------------------------------------
     25   1797       0  15%  2.0  WD-WCC4M6UXJ7AD  /dev/sdc  media1
     25   1060       0  12%  3.0  WD-WCC4N4NNR3XR  /dev/sdd  media2
     26   1759       0  14%  2.0  WD-WCC4N0430093  /dev/sdb  media3
     27    597       0   7%  4.0  ZW623Z5S         /dev/sda  media4
     22   1432       0   6%  4.0  ZGY9GHA0         /dev/sde  parity
     34     40       0  SSD  0.5  241801802914     /dev/sdf  -

The FP column is the estimated probability (in percentage) that the disk
is going to fail in the next year.

Probability that at least one disk is going to fail in the next year is 44%.
```

If one wishes to run the script as a non-root user but still generate the SMART report, **sudo** can be set up by adding the following to a file
in **/etc/sudoers.d/** with the following line. Or alternatively, by using the **visudo** command and adding the same below line. Where "username" is
the user the script will run as. Change the path to the snapraid binary if different.

```
username ALL=(root) NOPASSWD:/usr/bin/snapraid
```

Then, add the user to the sudo group like so. It's possible the group name
is different on other distros.

```
usermod -aG sudo username
```

Note that no analysis of the output is done, it is just included for the users
reference. Comment out and set to yes to enable this feature. Off by default.

### spin\_down\_disks

Get SnapRAID to spin down all Hard Disks after the script has completed all operations. As above, this requires the script to
be ran as root or for sudo to be set up to call "snapraid down" as a non-root user (see above method). Comment out and set to "yes" to enable this
feature. Off by default.

The output in the notification email looks like this:

```
##############################
# SnapRAID-DAILY: HDD Spin-Down
##############################
Spindown...
Spundown device '/dev/sde' for disk 'parity' in 396 ms.
Spundown device '/dev/sdd' for disk 'media2' in 446 ms.
Spundown device '/dev/sdc' for disk 'media1' in 452 ms.
Spundown device '/dev/sda' for disk 'media4' in 878 ms.
Spundown device '/dev/sdb' for disk 'media3' in 1018 ms.
```

### start\_hook1-N

Specify the path to a number of hook scripts that are called when the script completes its initial checks and determines the intial status of the
array is OK but before **SnapRAID** touch/diff/sync/scrub operations are carried out. All must be executable. Up to 5 are supported.

These are primarily intended to stop a list of services that could interact with files in the **SnapRAID** array and thus cause sync/scrub operations to exit 
with an error while the script is running. However they could be used for anything else as desired.

Note also that these can be anything that is called from the command line, they do not have to take the form of a bash script. Python scripts, Perl scripts or executables
should also work too.

To use single or multiple start hooks, set the **start_hook1-N** parameters in the config file **/etc/snapraid-daily.conf** like so:

```bash
start_hook1="/usr/bin/snapraid-daily-service-hook"
start_hook2="/path/to/hook2"
...
start_hookN="/path/to/hook5"
```

Recall that it is required that all of the above hooks be executable.

Start with **start_hook1** and continue to **start_hookN** where N is the number of hooks that are desired. Up to 5 are supported.

See the section on hooks later for more information.

Comment out if not using.

### end\_hook1-N

Specify a path to a number of hook scripts that are called when the script completes all sync/scrub operations and before sending the final notification email. They are also
called if the script exits in an error condition. Up to 5 are supported. All must be executable.

Like the start hook(s) above, these are primarily intended to re-start a list of services that have been previously stopped and that could interact with files in the **SnapRAID** array
and thus cause sync/scrub operations to exit in an error while the script is running. However again they could be used for anything else as desired.

As before, note also that these can be anything that is called from the command line, they do not have to take the form of a bash script. Python scripts, Perl scripts or executables
should also work too.

As before, to use single or multiple end hooks, set the **end_hook1-N** parameters in
the config file **/etc/snapraid-daily.conf** like so:

```bash
end_hook1="/usr/bin/snapraid-daily-service-hook"
end_hook2="/path/to/hook2"
...
end_hookN="/path/to/hook5"
```

Recall that it is required that all of the above hooks be executable.

Start with **end_hook1** and continue to **end_hookN** where N is the number of hooks that are desired. Up to 5 are supported.

These can be the same as the start hook(s) used if they accept the "start" and "end" arguments. See the section on hooks later for more information.

Comment out if not using.

### notification\_hook1-N

Specify a path to a number of custom notification hooks here if an alternative form of notification to emails with **mutt** is preferred. All must be executable. They
can used instead of or in addition to the emails if desired. Up to 5 are supported.

As before, note also that these can be anything that is called from the command line, they do not have to take the form of a bash script. Python scripts, Perl scripts or executables
should also work too.

To use the notification hook(s), set the **notification_hook1-N** parameters in the config file (**snapraid-daily.conf**) like so:

```bash
notification_hook1="/usr/bin/snapraid-daily-apprise-hook"
notification_hook2="/usr/bin/snapraid-daily-healthchecks-hook"
...
notification_hookN="/path/to/hook"
```

Again, recall that it is required that all of the above hooks be executable.

Start with **notification_hook1** and continue to **notification_hookN** where N is the number of hooks that are desired. Up to 5 are supported. 

As above, see the section on hooks later for more information.

Comment out if not using.

### Hook Variables

If any variables are required for the start/end or notification hooks they can be specified in the config file through the use of "export" - Example:

```bash
export var1="whatever etc."
```

This is better than requiring additional configuration files for hook scripts. Remember not to forget the "export"!

## Sample Config File

Shown below is the bare minimum that is required in a snapraid-daily.conf config file for all functionality. Feel free to add
comments using **\#** accordingly.

```bash
# Snapraid Config Path
snapraid_config_file_path="/etc/snapraid.conf"    

# Email Notification Parameters
# Muttrc File and Email Address to send notification
# emails to
muttrc_path="/opt/email_notifications/mutt/muttrc"   
email_address="server@example.com"  

# Deletion and Moved Thresholds
deletion_threshold=200 
moved_threshold=200
updated_threshold=200

# Sync Pre Hash Function (on by default)
sync_pre_hash="yes"

# Scrub Age and Percent
scrub_percent=10  
scrub_age=7

# Extra Options
#disable_emails_on_success="no"
#smart_report="no"
#spin_down_disks="no"

# Not Recommended Options (Off by default)
#force_zero="no"
#force_empty="no"
#force_uuid="no"

# Hooks
#start_hook1="/path/to/start/hook"
#end_hook1="/path/to/end/hook"
#notification_hook1="/path/to/notification/hook"

```
See a more detailed example with explanatory comments here:

* [https://github.com/zoot101/snapraid-daily/blob/main/config/snapraid-daily.conf](https://github.com/zoot101/snapraid-daily/blob/main/config/snapraid-daily.conf) 

See also an example that uses the hook scripts from the SnapRAID-DAILY-Hooks repo
[HERE.](https://github.com/zoot101/snapraid-daily-hooks)

* [https://github.com/zoot101/snapraid-daily/blob/main/docs/examples/snapraid-daily.conf](https://github.com/zoot101/snapraid-daily/blob/main/docs/examples/snapraid-daily.conf)

## Setting up Email Notifications

The main notification method the script uses is emails. In the opinion of the author, email is be best way to get detailed information.

A valid muttrc configuration is required to send email notifications.

The following sample configs are provided along with instructions on how to set them up.

* Gmail via App Passwords
* Outlook via Oauth2
* Gmail via Oauth2
* Fastmail.com   
* ntfy (Self-Hosted)   

Detailed instructions are provided in the below link on how to set **mutt** up to send emails with the script.
 
* [https://github.com/zoot101/snapraid-daily/blob/main/docs/muttrc-examples/](https://github.com/zoot101/snapraid-daily/blob/main/docs/muttrc-examples/)

If desired, to disable emails entirely and rely upon an alternative form of notification comment out the **muttrc_path** or **email_address** in the config file and use the
**notification_hook1-N** instead (see below).

## Automation with Systemd

By default the below systemd files are bundled with the debian package installation, but are not enabled by default. 

* `/usr/lib/systemd/system/snapraid-daily.service`    
* `/usr/lib/systemd/system/snapraid-daily.timer`    
* `/usr/lib/systemd/system/snapraid-sync.service`    
* `/usr/lib/systemd/system/snapraid-sync.timer`    
* `/usr/lib/systemd/system/snapraid-scrub.service`    
* `/usr/lib/systemd/system/snapraid-scrub.timer`    

If one installed using the manual procedure above, the above files are in **/etc/systemd/system** instead, the procedure is the same regardless.

These files do the following:

1. **snapraid-daily.service** : Runs a sync, then a scrub (the default).    
2. **snapraid-sync.service** : Syncs the array only (uses the -s argument).    
3. **snapraid-scrub.service** : Scrubs the array only (uses the -c argument).    

These are intended to cover both of the following cases:

* Default behaviour of Sync followed by a Scrub each time the script is called
* Completely seperate Sync and Scrub operations

Firstly, it's a good idea to test the service works correctly by starting the desired one manually like so:

```bash
sudo systemctl start snapraid-daily.service
```

Then, to get detailed information one can use **journalctl** to inspect the logs.

```bash
sudo journalctl -u snapraid-daily.service --since today
```

If the service runs without issue, the next step is to enable the timers to run the corresponding service automatically.

To enable any one of the timers do the below - enabling the services is not required, since they are configured as oneshots and are not intended to be ran at start up. 

If one wishes to run the script with the default behaviour (Run a sync, followed by a scrub), then start and enable the **snapraid-daily.timer** file as below.

```bash
sudo systemctl start snapraid-daily.timer
sudo systemctl enable snapraid-daily.timer
```

If one wishes to schedule seperate sync and scrub operations start and enable both the **snapraid-scrub.timer** and **snapraid-sync.timer** files as shown below.

```bash
sudo systemctl start snapraid-sync.timer
sudo systemctl enable snapraid-sync.timer
sudo systemctl start snapraid-scrub.timer
sudo systemctl enable snapraid-scrub.timer
```

The default timer run times are :

* **snapraid-sync.timer** : Twice daily - At 06:00 and 18:00    
* **snapraid-scrub.timer** : Twice weekly - Mondays and Fridays at 21:00    
* **snapraid-daily.timer** : Daily - At 06:00    

To adjust any of these, if the script was installed by the package, it's best to create a seperate copy of the timer file in **/etc/systemd/system/** like below,
and then to edit that file directly. 

```bash
# If installed by the package - create a copy like so:
sudo cp /usr/lib/systemd/system/snapraid-daily.timer /etc/systemd/system/snapraid-daily.timer
```

This is because systemd will take precedence for files in **/etc/systemd/system** over **/usr/lib/systemd/system**. This way, any user modifications are not undone when
upgrading to new versions of the package installation.

On the other hand if one installed via the manual procedure above, then the timer file(s) can be edited directly in **/etc/systemd/system**.

An example timer file that shows different options on how to specify when it will 
run is [HERE](https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-examples/sample-timer.timer) and can be used as example to change the default runtimes
if desired.

It is not recommended to edit any of the service files directly. It is instead better to create drop-in files by using:

```bash
sudo systemctl edit snapraid-daily.service
```

Lastly, if one does change anything in the service files or the timer files above, remember to reload systemd afterwards like so:

```bash
systemctl daemon-reload
```

Some further examples are provided in the docs directory for the drop-in files that can be used to configure automatic restarts or systemd hardening (see below).

* [https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-drop-ins](https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-drop-ins)    

## Running as a Standard User with Systemd

If installed via package, the script is already setup to run as a non-root user depending on what was selected for the prompts, thus the below procedure
need not be followed.

However if one wishes to change the user that the script is ran as after installation, that can be done like so:

```bash
sudo dpkg-reconfigure snapraid-daily
```

For manual installations, in the [instructions above](#manual-installation) a drop-in file was already generated here, and also the below procedure need not be followed.

* `/etc/systemd/system/snapraid-.service/user.conf`

Regardless, setting up the script to run as a non-root user is explained below.

To set systemd up to run the script as a user other than root, do the following:

* First, create a directory **/etc/systemd/snapraid-.service.d/**    
* Next, create a file called **user.conf**    
* Then the following into that file and place it in the above directory    

```bash
[Service]  
User=username   
Group=groupname
```

Where **username** and **groupname** are the user and group names of the user one wants to run SnapRAID, and thus **SnapRAID-DAILY** as.

The naming of the **/etc/systemd/system/snapraid-.service.d/** directory will cause it to be picked up by all of the systemd service unit files
installed by the script, or any services with a name of the structure: **snapraid-\[something\].service**

Lastly, reload systemd:     
```bash
sudo systemctl daemon-reload
```

As before, futher example drop-in files and timer files for systemd along with some notes are included here:

* [https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-drop-ins](https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-drop-ins)    
* [https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-examples/sample-timer.timer](https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-examples/sample-timer.timer)    

## Alternative - Automation with Cron

The vast majority of users are likely running a distro that uses Systemd. As a result that is what the focus has been placed on in
the documentation here. Also, if one is running a distro that uses systemd it's recommended to stick with using systemd timers to automate
running for the script.

However, if one is using a distro that uses **cron** instead, or just wants to use **cron** instead - some examples and notes on using
**cron** to run the script are provided in the docs directory here:

* [https://github.com/zoot101/snapraid-daily/blob/main/docs/cron-examples/](https://github.com/zoot101/snapraid-daily/blob/main/docs/cron-examples/)

# External Hooks

The script supports the use of external hooks when the script starts, completes or exits in error. The use of custom notification hooks if a user
wishes to use an alternative form of notifcation than standard emails are also supported. Up to 5 of each are supported which gives a lot of room for customisation.

A collection of Hook scripts that integrate into the main script are provided here:

* [https://github.com/zoot101/snapraid-daily-hooks](https://github.com/zoot101/snapraid-daily-hooks)

The following hook scripts are provided at the above link:

* Notification hook to use **Apprise** to support many services from ntfy, Telegram, Discord and more   
* Notification hook to use **Healthchecks.io**     
* Hook to stop and restart a list of services while **SnapRAID-DAILY** is running    

Detailed instructions are provided above on how to set them up with **SnapRAID-DAILY**. Using **Apprise**
comes highly recommended from the author!

## Notification Hooks

Up to 5 seperate notification hooks are supported.

The notification hook(s) can be used instead of the standard email notifications via **mutt** or used in addition to them.

A bash script is probably what is best to use here, but the hooks can be anything that is ran from the command line - it doesn't have to be a bash script per se.

If the **SnapRAID-DAILY** script ends in success, the notification hooks are called one-by-one on the command line like so:

```bash
"/path/to/notification/hook" "SnapRAID-DAILY: All OK" "/path/to/email/body"
```

The 1st argument is what would be the email subject, and the 2nd argument is what would be the file containing the text that would form the email body.

However, if the script ends in an error/warning, the hook script is called like so:

```bash
"/path/to/notification/hook" "SnapRAID-DAILY: Sync Warning(s)" "/path/to/email/body" "/path/to/command/log/file"
```

As before, the 1st argument is what would be the email subject, and the 2nd argument is what would be the file containing the text that would form the email
body. The 3rd argument is the log file of the **SnapRAID** command that caused the script to exit with an error.

It is recommended to test the notification hook(s) by calling them directly as detailed above to ensure they work as desired before using them with **SnapRAID-DAILY**.

To use the notification hook(s), set the **notification_hook1-N** parameters in the config file (**snapraid-daily.conf**) like so:

```bash
notification_hook1="/usr/bin/snapraid-daily-apprise-hook"
notification_hook2="/usr/bin/snapraid-daily-healthchecks-hook"
...
notification_hookN="/path/to/hook"
```

Again, note that it is required that all of the above hooks be executable.

Start with **notification_hook1** and continue to **notification_hookN** where N is the number of hooks that are desired. Up to 5 are supported. 

If for example, numbers are skipped - That is, **notification_hook1**, **notification_hook2**, and **notification_hook4** are specified, then
**notification_hook4** will be ignored as **3** has been skipped and not specified.

For most usage cases, it is likely that only one is required. In that case one can specify **notification_hook1** only and omit the others like so:

```bash
notification_hook1="/usr/bin/snapraid-daily-apprise-hook"
```

If any variables are required to be passed into the notification hook(s), they can be set in **snapraid-daily.conf** like so:

```bash
export var1="whatever"
```

See the package **SnapRAID-DAILY-Hooks** for some additional hook scripts that integrate  alongside the main script for alternative notification methods and start/end hooks.

An example config file that uses the start, end and notification hooks can be found here:

* [https://github.com/zoot101/snapraid-daily/blob/main/docs/examples/snapraid-daily.conf](https://github.com/zoot101/snapraid-daily/blob/main/docs/examples/snapraid-daily.conf)

# Start and End Hooks

The script can also be configured to execute a hook upon startup and also after all sync/scrub operations have been completed. As before, these hooks can be bash
scripts, or anything that can be called from the command line. Again up to 5 are supported.

A check is carried out for a non-zero (error) return code on the start hook(s), and the main script will exit if this condition is encountered on any one of them. This same error check is
not however carried out on the end hook(s) to ensure the script runs to end and the final notification is sent, however the printout of the overall result will be changed to "WARNING(S)"
in this case.

These hooks are primarily intended to start and stop a list of services that can access files in the **SnapRAID** array to allow **SnapRAID** to run without the risk of files being
modified while in use, but could be used for anything else.

The start hook(s) are executed after the main script has completed all of its initial checks and just before it starts to run **SnapRAID**
touch/diff/sync/scrub operations. The start hook(s) are also passed a "start" argument, and are called one-by-one like so:

```bash
/path/to/hook start
```

The end hook(s) are then executed after all sync/scrub operations have been carried out just before the final notification is sent. They are also executed if the
script exits due to an error condition encountered during any of the main **SnapRAID** operations (touch/diff/sync/scrub). The end hook(s) are
also passed an "end" argument and are called one-by-one like so:

```bash
/path/to/hook end
```

The use of the "start" and "end" arguments allows the same hook to be used at both the start and end of **SnapRAID-DAILY**. Note that
it is also possible to use different hooks at the start and end of the script if desired.

It is also not required to use a start **AND** end hook simultaneously, the user can use only the start hook(s) or end hook(s) as desired. The hooks also do not need to use the
"start" or "end" arguments either.

Once again its a good idea to test out the start and end hooks on their own by calling them directly as discussed above on the command line to ensure they
work as desired before using them directly with **SnapRAID-DAILY**.

To use either of these set the **start_hook1-N** or **end_hook1-N** parameters in the config file **/etc/snapraid-daily.conf** like so:

```bash
start_hook1="/usr/bin/snapraid-daily-service-hook"
start_hook2="/path/to/hook2"
...
start_hookN="/path/to/hook5"

end_hook1="/usr/bin/snapraid-daily-service-hook"
end_hook2="/path/to/hook2"
...
end_hookN="/path/to/hook5"
```

Note that it is required that all of the above hooks be executable.

Start with **start_hook1** and continue to **start_hookN** where N is the number of hooks that are desired. Do the same for **end_hook1** to **end_hookN**.
Up to 5 are supported.

If for example, numbers are skipped -  **start_hook1**, **start_hook2**, and **start_hook4** are specified, then **start_hook4** will be ignored as **3** has been skipped and not
specified. The same is true for the end hook.

For most usage cases, it is likely that only one is required. In that case one can specify **start_hook1** and **end_hook1** only and omit the others like so:

```bash
start_hook1="/usr/bin/snapraid-daily-service-hook"
end_hook1="/usr/bin/snapraid-daily-service-hook"
```

As before, if any variables are required to be passed into the notification hook, they can be set in **snapraid-daily.conf** like so:

```bash
export var1="whatever"
```

An example config file that uses the start,end and notification hooks can be found here:

* [https://github.com/zoot101/snapraid-daily/blob/main/docs/examples/snapraid-daily.conf](https://github.com/zoot101/snapraid-daily/blob/main/docs/examples/snapraid-daily.conf)

# SnapRAID Sync and Scrub Options

SnapRAID sync is invoked with the following options:   
* -c : To specify the config file for snapraid itself
* -v : Verbose Mode   
* -l : Use SnapRAID's logging function   
* -h : Read data twice during sync, as an additional safeguard against silent errors.   

SnapRAID scrub is invoked with the following options:
* -c : To specify the config file for snapraid itself
* -p : To scrub the percentage in snapraid-daily.conf
* -o : To only consider the age from snapraid-daily.conf   
* -v : Verbose Mode
* -l : Use SnapRAID's logging function 

# Detailed Operation

As optional reading, a detailed description of all the steps carried out by **SnapRAID-DAILY** are outlined below:

## Step 1 - Initial Checks

The script carries out an initial check of everything before it will even attempt to interact with **SnapRAID**.

Initially the config file **snapraid-daily.conf** is read, and its contents are checked. If anything is undefined, a default
value is assumed.

If the main config file for SnapRAID itself is not present in the default location or doesn't exist, the script will continue with all defaults.

The script will then check for an updated version on the Github page if the parameter to disable the update check is not used in the config file.

Next checks are carried out for the script dependencies: awk, grep, sed, mktemp, tee and SnapRAID itself. It will exit if any of these
are not present.

Next, a check on the first defined content file in the SnapRAID config (**/etc/snapraid.conf**) is checked to see if it exists and is
writable. This is to ensure the script is being ran as the right user, and serves as a good sanity check to see if the content files exist and
are writable.

One could check all config files exist,  but given that there is usually a copy on each disk, that would mean potentially
waking all the disks from standby which would be undesirable if a sync/scrub is not ran because of a subsequent issue.

Likewise, it was decided not to check if the parity files exist to again prevent waking the disks unless a sync or a
scrub operation are **actually** going to be carried out.

If there is an issue with not being able to access the parity files or content files, the status command will flag this in the case of
a missing content file, and the sync or scrub will fail in the case of a missing parity file, and the user will be notified anyway.

## Step 2 - Check SnapRAID Array Current Status

Checks the Array for Errors or if Touch is required using `snapraid status`

If errors are encountered at this point, the script will exit and send a notification email to the user. It will continue to
do this each time the script is invoked, and stop here until the user intervenes to address whatever the error is.

If a sync was found to be in progress (that is - the last sync was interrupted), and **\--scrub-only** is NOT specified, the
script will continue as the solution to this is usually to let the sync complete. If **\--scrub-only** is specified, the script
will exit here.

A check is also carried out if **SnapRAID** is already in use, ie. whether a **sync** or **scrub** etc. is currently running.
SnapRAID will not allow multiple instances of itself processing the same array.

The script will exit in this case and the user is also notified explicity of this.

## Step 3 - Run Start Hooks If Given

After all checks are completed, and SnapRAID's status looks okay, the start hooks are called here one-by-one if specified in the config file.
If any of the start hooks report an error, the script will exit here and notify the user via email or notification hooks.

## Step 4 - Run Touch if Required

If it is determined from the initial check that 1 or more files do not have sub-zero timestamps, **snapraid touch** is ran to
add the sub-zero timestamps.

Touch of files added to the array by default will run the next time the script is executed after the files have been added.

SnapRAID is invoked with **-v** & **-l** switches to turn on verbose mode and logging, this is to aid in quick debugging if
errors are detected during the touch.

The output is monitored for errors and if any are detected, the script will exit, send a notification email to the user or call
the notification hooks and attach the output of the log created with the "-l" argument to SnapRAID.

The idea here is that one can quickly know what the error is via the notification email alone.

If it is determined that the touch operation is not required, this step will be skipped entirely.

This step is also skipped if the **\--scrub-only** argument to the script is used.

## Step 5 - Check Array for Changes

Runs **snapraid diff** to check the array for changes to determine if a sync is required or not.

If no changes are detected, the script will skip the sync entirely. If changes are detected, the sync will proceed. In the event that
the **-s, --sync-only** is used, the script will exit here if no changes are detected.

However if either the threshold for deletions, moves or updates that are defined in the config file **snapraid-daily.conf** are found to be
exceeded, the script will exit and notify the user via email and/or call the notification hook(s) if present.

The theory is that if excess deletions, moves or updates are detected, it could very well be accidental, and a subsequent sync could prevent
the recovery of that data.

For subsequent runs, the script will continue to do this and stop at this point until the user intervenes. This step is skipped if the
**\--scrub-only** argument is used.

## Step 6 - Run Sync to Update the Array

Runs **snapraid sync** to update the array. The start-time and finish time are monitored to compute the duration so it can be added to the
main log that will form the email body.

The **-v** and **-l** switches are used to turn on verbose mode and logging, this is to aid in quick debugging if errors are detected
during the sync operation.

The **-h** option is also used to read data a 2nd time during the sync. This is to serve as an additional safeguard against silent errors
during what is an extreme condition for the machine whereby all disks are spinning at the same time. See the SnapRAID documentation here for
more information:     
* [https://www.snapraid.it](https://www.snapraid.it)

The output is monitored for errors and if any are detected, the script will exit, send a notification email to the user and/or call the notification
hook and attach the output of the log created with the **-l** argument to SnapRAID.

The idea here is that one can quickly know what the error is via the notification email/other method alone.

If it is determined that the sync operation is **NOT** required from the above Step of checking for changes, this step will be skipped
entirely.

This step is also skipped if **\--scrub-only** is active.

## Step 7 - Run Scrub to Check for Silent Corruption

Runs Scrub using the **scrub_percent** & **scrub_age** input parameters specified in the config file **snapraid-daily.conf**. The start-time
and finish time are computed such that is can be added to the main log that will form the email body.

Before the scrub is carried out, the array is once again checked for changes since the last sync so the scrub can correctly run.

In the default setup where **SnapRAID-DAILY** is called with no arguments, this check should not find any changes since a sync was carried
out moments ago. However when one is using the **-c, --scrub-only** option this may not be the case.

This is required as **SnapRAID** will exit with an error during a scrub if it finds files that have been modified and not synced.

In this case, the script will exit and the user will be notified via email/notification hook(s) explicitly that a sync is required.

The scrub is then called with the **-v** & **-l** switches to turn on verbose mode and logging, this is to aid in quick debugging if errors
are detected during the scrub operation.

The output is monitored for errors and if any are detected, the script will exit, send a notification email to the user and/or call the notification hook(s),
and attach the logfile from the output of the log created with the **-l** argument to SnapRAID.

Once again, this is to allow for quick debugging to know exactly what the error is from the notification email alone.

If the scrub does encounter issues such as silent corruption, the status check at the start of the script when ran the next time will flag them,
and the script will subsequently exit each time it is invoked until the user intervenes to attempt a manual fix.

## Step 8 - Run End Hooks If Given

The end hooks are now called here one-by-one if specified in the config file. If the any of the end hooks exit in error, the script will print a warning and
still continue so that the final notification(s) are sent.

The end hooks are also ran in the event of error conditions for SnapRAID touch/diff/sync/scrub operations above. If for example one stops a list of services
with the start hook(s), this means that the services are always restarted via the end hook(s) regardless of the outcome of the script.

## Step 9 - Generate SMART Report and Spin Down Disks if Enabled

Next, the script will call **snapraid smart** and **snapraid down** to generate a SMART Report and spin the disks down if these parameters are
enabled in the configuration file. If the script is not ran as root, it will attempt to call those commands using sudo.

## Step 10 - Send Final Notification Email

If no errors are detected during the touch, sync and scrub, or just touch & sync, or just scrub (depending on whether the **-s, \--sync-only**
or **-c, \--scrub-only** arguments are used):

If emails on success are not disabled, the final condensed log file for the email is sent to the user. This will contain an concise output of all the operations carried
out and what the result was (an example is shown below).

## Step 11 - Run Notification Hooks if Given

Lastly the notification hooks are called here one-by-one if specified in the config file.

# Sample Output

A sample email notification of the script is shown below, this uses the service hook from here:

* [https://github.com/zoot101/snapraid-daily-hooks](https://github.com/zoot101/snapraid-daily-hooks)

```bash
##############################
# SnapRAID-DAILY Version: 1.5.4
##############################
Initialized at 15:26:30 on 17/10/2025
 * Hostname: server.home.lan
 * Host OS: Debian GNU/Linux 13 (trixie)
 * SnapRAID Version: none
Input Options:
 * Run-Sync: YES
 * Sync Pre-Hash: YES
 * Run-Scrub: YES
 * Scrub-Percent: 5
 * Scrub-Age: 2 days and older
 * Override Thresholds: NO
 * Deletion Threshold: 1000
 * Moved Threshold: 1000
 * Updated Threshold: 1000
 * SMART Report: YES
 * Spin-Down HDDs: YES
Hooks:
 * Start-Hook: YES (1)
 * End-Hook: YES (1)
 * Notification Hook: NO
Run-Log is Below:

##############################
# SnapRAID-DAILY: Initial Status Check
##############################
15:26:30 : Checking current status...
15:26:40 : No Issues Found in Initial Check
15:26:40 : Ready to run SnapRAID operations
15:26:40 : Touch Not Needed...

##############################
# SnapRAID-DAILY: Start Hook(s)
##############################
15:26:40 : Calling Start Hook 1/1...
15:26:40 : 1 Service(s) defined in config
15:26:40 : Stopped Service 1/1: smbd
15:26:40 : Start Hook 1/1 Done
15:26:40 : All Start Hooks completed successfully

##############################
# SnapRAID-DAILY: Difference Check
##############################
15:26:40 : Checking array for changes...
15:26:52 : Changes Detected
 * Equal: 1632997
 * Added: 8
 * Removed: 8
 * Updated: 0
 * Moved: 0
 * Copied: 0
 * Restored: 0
15:26:52 : Proceeding to sync...

##############################
# SnapRAID-DAILY: Sync
##############################
15:26:52 : Starting Sync on 17/10/2025...
15:27:56 : Sync Completed on 17/10/2025
15:27:56 : Duration: 0 hours, 1 minutes, 4 seconds
15:27:56 : Sync was Successful
15:27:56 : Array Changes Found & Updated:
 * Added: 8
 * Removed: 8
 * Updated: 0
 * Moved: 0
 * Copied: 0
 * Restored: 0

##############################
# SnapRAID-DAILY: Scrub
##############################
15:27:56 : Checking if Array is still up to date...
15:28:11 : Array is Up-to-Date - Proceeding
15:28:11 : Starting Scrub on 17/10/2025
15:28:11 : Scrubbing 5% older than 2 days...
15:29:12 : Scrub Completed at 17/10/2025
15:29:12 : Duration: 0 hours, 1 minutes, 1 seconds
15:29:12 : Scrub was successful
15:29:12 : Scrubbed 5% older than 2 days

##############################
# SnapRAID-DAILY: End Hook(s)
##############################
15:29:12 : Calling End Hook 1/1...
15:29:12 : 1 Service(s) defined in config
15:29:13 : Started Service 1/1: smbd
15:29:13 : End Hook 1/1 Done

15:29:13 : All End Hooks completed successfully

##############################
# SnapRAID-DAILY: SMART Report
##############################
SnapRAID SMART report:

   Temp  Power   Error   FP Size
      C OnDays   Count        TB  Serial           Device    Disk
 -----------------------------------------------------------------------
     27   1797       0  15%  2.0  WD-WCC4M6UXJ7AD  /dev/sdc  media1
     28   1060       0  12%  3.0  WD-WCC4N4NNR3XR  /dev/sdd  media2
     29   1757       0  14%  2.0  WD-WCC4N0430093  /dev/sdb  media3
     31    595       0   7%  4.0  ZW623Z5S         /dev/sda  media4
     25   1430       0   6%  4.0  ZGY9GHA0         /dev/sde  parity
     35     39       0  SSD  0.5  241801802914     /dev/sdf  -

The FP column is the estimated probability (in percentage) that the disk
is going to fail in the next year.

Probability that at least one disk is going to fail in the next year is 44%.

##############################
# SnapRAID-DAILY: HDD Spin-Down
##############################
Spindown...
Spundown device '/dev/sdd' for disk 'media2' in 448 ms.
Spundown device '/dev/sde' for disk 'parity' in 467 ms.
Spundown device '/dev/sda' for disk 'media4' in 870 ms.
Spundown device '/dev/sdb' for disk 'media3' in 1025 ms.
Spundown device '/dev/sdc' for disk 'media1' in 1033 ms.

##############################
# SnapRAID-DAILY: Array Status
##############################
15:29:14 : Current Status of the Array is as below:
SnapRAID status report:

   Files Fragmented Excess  Wasted  Used    Free  Use Name
            Files  Fragments  GB      GB      GB
  220455     180     653       -    1626     339  82% media1
  388629     794    2840       -    2163     786  73% media2
  581566     275     888       -    1533     431  78% media3
  442349    2035    7323     1.7    3144     787  80% media4
 --------------------------------------------------------------------------
 1632999    3284   11704     1.7    8468    2346  78%


 16%|           *                    o          o          o          o
    |           *         o          *          *          *          *
    |           *         *          *          *          *          *
    |           *         *          *          *          *          *
    |           *         *          *          *          *          *
    |           *         *          *          *          *          *
    |           *         *          *          *          *          *
  8%|           *         *          *          *          *          *
    |*          *         *          *          *          *          *
    |*          *         *          *          *          *          *
    |*          *         *          *          *          *          *
    |*          *         *          *          *          *          *
    |*          *         *          *          *          *          *
    |*         o*         *          *          *          *          *
  0%|*_________o*___o_____*__________*__________*__________*__________*___o
     6                    days ago of the last scrub/sync                 0

The oldest block was scrubbed 6 days ago, the median 3, the newest 0.

No sync is in progress.
4% of the array is not scrubbed.
No file has a zero sub-second timestamp.
No rehash is in progress or needed.
No error detected.

##############################
# SnapRAID-DAILY Result: SUCCESS
##############################

Regards,
server.home.lan

```

# Further Examples

For examples on how to automate via systemd timers, set up a valid muttrc config for emails, some notes on SnapRAID itself, a sample hook script, 
or notes on how to use cron instead of systemd have a look here.

* [https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-examples/sample-timer.timer](https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-examples/sample-timer.timer)
* [https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-drop-ins](https://github.com/zoot101/snapraid-daily/tree/main/docs/systemd-drop-ins)
* [https://github.com/zoot101/snapraid-daily/tree/main/docs/snapraid-stuff](https://github.com/zoot101/snapraid-daily/tree/main/docs/snapraid-stuff)
* [https://github.com/zoot101/snapraid-daily/tree/main/docs/sample-config](https://github.com/zoot101/snapraid-daily/tree/main/docs/sample-config)
* [https://github.com/zoot101/snapraid-daily/tree/main/docs/muttrc-examples](https://github.com/zoot101/snapraid-daily/tree/main/docs/muttrc-examples)
* [https://github.com/zoot101/snapraid-daily/tree/main/docs/cron-examples](https://github.com/zoot101/snapraid-daily/tree/main/docs/cron-examples)
* [https://github.com/zoot101/snapraid-daily/tree/main/docs/examples/hook-example](https://github.com/zoot101/snapraid-daily/tree/main/docs/examples/hook-example)

# Creating your own Debian Package

Given the author uses Debian as their daily driver, a debian directory containing what is required to build a debian package is included here.

While it's not necessary, if one wants to build their own debian package, they can do the following if they are running a debian based distribution.

Again download the latest source code archive from the releases page [HERE](https://github.com/zoot101/snapraid-daily/releases) and extract it:

```bash
# Install build dependencies
sudo apt install debhelper dh-exec debconf

# Extract the archive 
unzip snapraid-daily-1.5.2.zip      # For the Zip File
tar xvf snapraid-daily-1.5.2.tar.gz # For the Tar File

cd snapraid-daily-1.5.2

# Create a source archive using dh_make, answer "yes" to
# the prompts. The default maintainer details are your username and
# hostname. This is fine for a self created package.
dh_make -s --createorig

# Build the package
dpkg-buildpackage -uc -us
```

A new Debian package should be created in the parent directory that can be installed with **dpkg** or with **apt** as shown above.

## Removing the Dependency on SnapRAID

Normally the author would recommend installing **SnapRAID** itself from the official repos.

However, in the cases where one has installed **SnapRAID** from outside the official Repos, and wants to install this script via the package,
it may be desirable **NOT** to have the **SnapRAID-DAILY** package depend on **SnapRAID** itself, so one can install **SnapRAID-DAILY** via
the package without the main **SnapRAID** package from the offical repos being automatically installed.

In that case, to remove the dependency - do the following:

```bash
# Repeat the above procedure to download and extract the "Source Code" archive
# Then after extracting, edit the debian/control file
nano debian/control # Or whichever edit you prefer

# And delete the following line:
 snapraid (>=11.0),

# Then rebuild the package as above
```

# Return Codes

The Script Returns the following codes for the following conditions. This can be useful to direct systemd or a seperate master script to
carry out further actions depending on the code. 

* 0: Success    
* 1: All Errors    
* 2: SnapRAID already in use    
* 3: Files Modified During Sync    
* 5: Thresholds Exceeded   

# Issues

Bug reports here on Github are welcome - don't hestitate if you find something wrong.

* [https://github.com/zoot101/snapraid-daily/issues](https://github.com/zoot101/snapraid-daily/issues)

# Credits

Most of the script is entirely from the author, but a lot of inspiration was got from the following similar scripts:

Original Bash Script (from Zack Reed):

* [https://zackreed.me/snapraid-split-parity-sync-script/](https://zackreed.me/snapraid-split-parity-sync-script/)

Snapraid-Runner:

* [https://github.com/Chronial/snapraid-runner](https://github.com/Chronial/snapraid-runner)

Also a bit thank you to Andrea Mazzoleni for this excellent software:

* [https://github.com/amadvance/snapraid](https://github.com/amadvance/snapraid)     
* [https://www.snapraid.it](https://www.snapraid.it)    

Lastly - Thank you for your interest in this script. Hopefully it can be of use to other people also.

