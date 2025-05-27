# SnapRAID-Daily - Notes on cron jobs

Most systems running this script will likely use systemd.
However below are some examples to get it to run via cron
instead.

Setting up of cron itself is left to the user and not considered here.

* To emulate the default installation, put the script somewhere along most users $PATH variables - /usr/bin/ usually.   
* Put the config file in /etc.   
* Alternatively put the script and config file in their own directory somewhere. The config file will be read by the script if its in the same directory.   

# Cron Tab Line examples

The below should work assuming the script is in **/usr/bin**, change the path accordingly.

```bash
# Sync the Array Only Every day at 06:00 and 18:00
00 06,18 * * * "/usr/bin/snapraid-daily -s"

* Scrub the Array Only Every day at 03:00
00 03 * * * "/usr/bin/snapraid-daily -c"

* Scrub the Array Only Every Friday Night at 21:00
00 21 * * 5 "/usr/bin/snapraid-daily -c"

* Run the full Sync -> Scrub (Default) Every Day at 04:00
00 04 * * * "/usr/bin/snapraid-daily"
```

etc...

(Change the path to the script above if needed)

There are many good crontab generators online if one has a search,
here is one such example:
https://crontab-generator.org

# Knowing the Script is Running

The author is no expert on cron, but the logging function of systemd
seems vastly superior (open to correction!).

Sometimes it can be difficult to know the script is actually running,
to help with that one can check the **/tmp** directory for the logfiles
the script will generate:   
```bash
snapraid-daily.Xu83jf.txt

# etc.
```

