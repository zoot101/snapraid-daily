---
title: snapraid-daily.conf
section: 1
header: Config File User Manual
footer: snapraid-daily.conf
---

# NAME
**snapraid-daily.conf**

# DESCRIPTION

Main configuration file for the snapraid-daily script.

To be placed in either:

* **/etc/snapraid-daily.conf**    
* Same directory as the main script    

If installed via the debian package, a sample configuration
file is already placed at the 1st location above that can be
edited by the user.

Overriding the default config file can also be accomplished by
using the **-f, \--config [PATH-TO-CONFIG]** as an input argument
to the script.

The package installation will also place a sample file in the docs
location below.    
**/usr/share/doc/snapraid-daily/sample-configs/snapraid-daily.conf**

This can be used as a template to generate the
optimum config file in the default location:    
**/etc/snapraid-daily.conf**

Finally if the script cannot find any configuration file it will
continue with the defaults (See below **CONTENTS** section)

# CONTENTS

The main parameters included in the file are:

* **snapraid_config_file_path**    
* **muttrc_path**    
* **email_address**    
* **deletion_threshold**    
* **moved_threshold**    
* **scrub_percent**    
* **scrub_age**    

If any of the above are missing, defaults are loaded,
see below:

## snapraid\_config\_file\_path

This is the path to the main config file defining the array
for snapraid itself. It is usually **/etc/snapraid.conf**
but in the event that it is at a different location, it
can be specified here. The default is **/etc/snapraid.conf**

This is useful for the situation where the user may be running
multiple SnapRAID arrays on the same system.

## muttrc\_path

This is the path for the muttrc file that is used for sending
email notifications. No emails are sent if this is omitted.
The default is empty, whereby no emails are sent.

See the example here to set up the email notifications:    
**/usr/share/doc/snapraid-daily/muttrc-sample/muttrc**

## email\_address

Main email address to send the notification emails to. The
default is none, thus disabling email notifications.

## deletion\_threshold

If the number of files deleted since the last sync is
found to be greater than this number, then the script
will exit and notify the user via email. Must be a postive
number. The default is **100**

## moved\_threshold

As above, but for files moved. Must be a positive number.
The default is **100**

## scrub\_percent

The percentage of the array to scrub. The default is **8%**

## scrub\_age

The age of files in days to scrub. The default is **21 days**

# SAMPLE CONFIG FILE CONTENTS (snapraid-daily.conf)

Shown below is the bare minimum that is required in
a snapraid-daily.conf config file. Feel free to add
comments using **\#** accordingly.

* **snapraid_config_file_path=\"/etc/snapraid.conf\"**    
* **muttrc_path=\"/opt/email_notifications/mutt/muttrc\"**    
* **email_address=\"server@example.com\"**    
* **deletion_threshold=200**    
* **moved_threshold=200**    
* **scrub_percent=10**    
* **scrub_age=7**    

# AUTHOR

Mark Finnan (mfinnan101@gmail.com)

# COPYRIGHT

Copyright (C) 2021 Mark Finnan

# FURTHER EXAMPLES

For examples on how to automate via systemd timers,
a sample config, and how to set up a valid muttrc
config for emails, have a look here.

* **/usr/share/doc/snapraid-daily/systemd-examples/**    
* **/usr/share/doc/snapraid-daily/systemd-drop-ins/**    
* **/usr/snare/doc/snapraid-daily/muttrc-example/**    
* **/usr/share/doc/snapraid-daily/sample-config/**    

# SEE-ALSO

snapraid-daily(1), snapraid(1), mutt(1), muttrc(5), systemd.unit(1)

