# SnapRAID-Daily - Notes on drop-ins

To have the drop in picked up by all services when ran, the drop in
should be placed here: (The user override is an example)
/etc/systemd/system/snapraid-.service.d/

# Modifing One Service

To modify only one service (Example: snapraid-daily), put the drop-in here:
/etc/systemd/system/snapraid-daily.service.d/

If the ".d" directory doesn't exist - create it. Alternatively one can use
this command to create the drop-in file.
$ systemctl edit snapraid-daily.service to create a drop in file.

# usergroup.conf

The usergroup.conf is a sample just to get the script to run as a non-root
user as detailed in the manpage snapraid-daily(1)

# restarts.conf

The restarts.conf is a sample to get systemd to automatically restart the
script if it is detected that some files were modified during a sync. Its
not completely perfect and probably needs some configuration. Feel free
to experiment

# harden.conf

The harden.conf is a sample to add systemd hardening to the service files
that run the script and lock down its permissions. These are strictly
unnecessary, but nice to have. At a minimum to use the ReadWritePath
setting needs to be configured.

# Timers - Better to edit directly

Note that for timers, the author finds the best thing is to edit the
of the **snapraid-daily.timer** (or whichever other timer file) in
**/etc/systemd/system/** instead of creating a drop-in.

Debian is pretty good in that it doesn't automatically overwrite anything
in the **/etc/** directory when new packages are being installed.

This is obviously not an issue if installing manually.

# See Also

* systemd.unit(1)  
* systemd.timer(1)  
* systemd-analyze(1)  

