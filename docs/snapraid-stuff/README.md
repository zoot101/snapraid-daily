# Collection of SnapRAID Notes - Might prove useful

Below is a collection of notes from various aspects of using SnapRAID
from the author - might be of use to someone.

# Sample /etc/snapraid.conf

I have included my own /etc/snapraid.conf as an example here. Again in
the event that it proves useful to someone.

# SnapRAID Autosave Option

The autosave option is a good idea to include in the main SnapRAID
config file espectially for large arrays.

This automatically saves the arrays state after processing
a certain amount of data during a scrub or a sync. This is good to
include as it prevents one from having to start from the beginning
in the event of an interruption for long sync or scrub operations.

See here:    
https://www.snapraid.it/manual

# Content File Recommendations

For the SnapRAID content files, the authors preference is to put a
copy of the content file on each data disk in the array and also in
one or more locations outside the array.

Putting the 1st defined content file outside
the array allows one to call "snapraid status" without waking
the data disks. Which is nice if they are Hard Drives that are
typically spun down.

Example part of config file. In this case the 1st path **/Appdata**
is not on the array but /Media1 to /Media8 represent the data
disks.

```bash
content         /Appdata/snapraid/content-file/content-file.content
content         /Media1/.snapraid/content-file.content
content         /Media2/.snapraid/content-file.content
content         /Media3/.snapraid/content-file.content
content         /Media4/.snapraid/content-file.content
content         /Media5/.snapraid/content-file.content
content         /Media6/.snapraid/content-file.content
content         /Media7/.snapraid/content-file.content
content         /Media8/.snapraid/content-file.content
```

# Comments on Very Large Number of Files

There is a limit to the number of files that is possible to put into
a SnapRAID array while filling the parity drive completely. That is
where the blocksize parameter in **/etc/snapraid.conf** comes in.

Usually this parameter does not need to be changed, but for very large
number of files changing it can prove beneficial.

By default about half the block size is wasted for every file
present in the array. This is important when the parity drive is the same size as 
the data drives. It does not arise if the parity drive is bigger.

In the case where the drives are the same size and one is using ext4, one can
format the parity drive with the -T largefile4 switch for ext4 to get extra
space to lessen the impact of this. This gives about 1.5% of extra space.

The relevant format commands are below:    

```bash
# For Data Disks
mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0 /dev/sdX1

# For Parity Disks (to get the extra 1.5% of Space)  
mkfs.ext4 -m 0 -T largefile4 -E lazy_itable_init=0,lazy_journal_init=0 /dev/sdX1
```

(Where /dev/sdX1 is the partition to format)

The -m 0 and -E lazy\_itable\_init=0,lazy\_journal\_init=0 options
remove the spare space and set up the journal immediately, which is nice to have
completed directly after the disk is formatted.

See a worked example below for a sample calculation of the Max
number of files and the effect of reducing the blocksize.

```bash
Default Block Size = 256KiB = 262144B

EXAMPLE: 10TB Disks

# Parity Disks - Formatted with the largefile option
PARITY DISK = 9763194628 1k Blocks = 9.997511 * 10^12 B

# Standard Data Disks
DATA DISKs = 9687496532 1k Blocks = 9.919996 * 10^12 B

EXTRA SPACE = 77.515 * 10^9 B
WASTED SPACE ~ 0.5 * (Block Size) * Nfiles

# Max Number of Files in the array is:
NFiles(Max) ~ 591393

# Halving the Block Size to 128KiB Gives
NFiles(Max) ~ 1182875
```

See the SnapRAID documentation here:    
https://www.snapraid.it/manual

# Scrub Errors Notes

Here are some short notes about errors thrown up during scrub
and how to fix them as this is an area where the SnapRAID
documentation could be more clear in the opinion of the author.

## Finding the Effected Files

Here's an example status output with errors that have been found via
a scrub operation.

```bash
SnapRAID status report:

   Files Fragmented Excess  Wasted  Used    Free  Use Name
            Files  Fragments  GB      GB      GB
     911       0       0     0.2       0       9   4% disk1
       7       0       0    -0.1       0       8   8% disk2
       4       0       0     0.0       0       8   8% disk3
       2       0       0     0.0       0       9   3% disk4
 --------------------------------------------------------------------------
     924       0       0     0.2       2      36   6%


 99%|                                                                     o
    |                                                                     *
    |                                                                     *
    |                                                                     *
    |                                                                     *
    |                                                                     *
    |                                                                     *
 49%|                                                                     *
    |                                                                     *
    |                                                                     *
    |                                                                     *
    |                                                                     *
    |                                                                     *
    |                                                                     *
  0%|o____________________________________________________________________*
     1                    days ago of the last scrub/sync                 0

The oldest block was scrubbed 1 days ago, the median 0, the newest 0.

No sync is in progress.
1% of the array is not scrubbed.
No file has a zero sub-second timestamp.
No rehash is in progress or needed.
DANGER! In the array there are 2 errors!

They are from block 3094 to 3095, specifically at blocks: 3094 3095

To fix them use the command 'snapraid -e fix'.
The errors will disappear from the 'status' at the next 'scrub' command.
```

One of the issues is that you get the block number, but it's not clear what
the actual files effected are.

The 1st way (if using **snapraid-daily**), is to go back on the systemd logs using
journalctl, as usually the scrub will output the file effected while it's running.

```bash
sudo journalctl -u snapraid-daily
```

Another way is to re-scrub, but actually scrub the blocks effected with the below command.
This will usually give you the effected files. Taking the above example, the relevenat
command for this would be:

```bash
snapraid scrub -S 3094 -B 2
```

Here is a sample output from the above, now showing the names of the effected
files.

```bash
Scrubbing...
Data error in file '/mnt/disk2/test3/test_file.txt' at position '0', diff bits 58/128
100% completed, 1 MB accessed in 0:00

  disk1  8% | ****
  disk2 41% | *************************
  disk3 65% | ***************************************
  disk4 20% | ************
 parity  0% |
   raid  0% |
   hash  2% | *
  sched 29% | *****************
   misc  2% | *
            |______________________________________________________________
                           wait time (total, less is better)


       0 file errors
       0 io errors
       1 data errors
DANGER! Unexpected data errors! The failing blocks are now marked as bad!
Use 'snapraid status' to list the bad blocks.
Use 'snapraid -e fix' to recover them.
Use 'snapraid -p bad scrub' to recheck after fixing to clear the bad state.
```

## Fixing the Effected Files

This is relatively simple and well covered by the SnapRAID documentation. Generally
the following will do the job:

```bash
snapraid fix -e
snapraid -p bad scrub
```

The 2nd command is key - this will directly scrub the files that
have errors and remove them from being shown as an error in the status command.

Of course deleting the corrupted file is another way!

Here is a sample output of the above operation:

```bash
user1 : testing-vm @ /mnt/disk2/test3 $ snapraid -e fix
Self test...
Loading state from /mnt/disk1/.snapraid/disk-pool.content...
Searching disk disk1...
Searching disk disk2...
Searching disk disk3...
Searching disk disk4...
Selecting...
Using 0 MiB of memory for the file-system.
Initializing...
Selecting...
Fixing...
recovered test3/test_file.txt
100% completed, 492 MB accessed in 0:00

       1 errors
       1 recovered errors
       0 unrecoverable errors
Everything OK
user1 : testing-vm @ /mnt/disk2/test3 $ snapraid -p bad scrub
Self test...
Loading state from /mnt/disk1/.snapraid/disk-pool.content...
Using 0 MiB of memory for the file-system.
Initializing...
Using 96 MiB of memory for 64 cached blocks.
Selecting...
Scrubbing...
100% completed, 1 MB accessed in 0:00

  disk1  0% |
  disk2 40% | ************************
  disk3 58% | ***********************************
  disk4  6% | ***
 parity  0% |
   raid  9% | *****
   hash  3% | **
  sched 28% | *****************
   misc  0% |
            |______________________________________________________________
                           wait time (total, less is better)

Everything OK
Saving state to /mnt/disk1/.snapraid/disk-pool.content...
Saving state to /mnt/disk2/.snapraid/disk-pool.content...
Saving state to /mnt/disk3/.snapraid/disk-pool.content...
Saving state to /mnt/disk4/.snapraid/disk-pool.content...
Verifying...
Verified /mnt/disk1/.snapraid/disk-pool.content in 0 seconds
Verified /mnt/disk2/.snapraid/disk-pool.content in 0 seconds
Verified /mnt/disk3/.snapraid/disk-pool.content in 0 seconds
Verified /mnt/disk4/.snapraid/disk-pool.content in 0 seconds
user1 : testing-vm @ /mnt/disk2/test3 $ snapraid status
Self test...
Loading state from /mnt/disk1/.snapraid/disk-pool.content...
Using 0 MiB of memory for the file-system.
SnapRAID status report:

   Files Fragmented Excess  Wasted  Used    Free  Use Name
            Files  Fragments  GB      GB      GB
     911       0       0     0.2       0       9   4% disk1
       8       0       0    -0.1       0       8   8% disk2
       4       0       0     0.0       0       8   8% disk3
       2       0       0     0.0       0       9   3% disk4
 --------------------------------------------------------------------------
     925       0       0     0.2       2      36   6%


 99%|*
    |*
    |*
    |*
    |*
    |*
    |*
 49%|*
    |*
    |*
    |*
    |*
    |*
    |*
  0%|*____________________________________________________________________*
     0                    days ago of the last scrub/sync                 0

The oldest block was scrubbed 0 days ago, the median 0, the newest 0.

No sync is in progress.
The full array was scrubbed at least one time.
No file has a zero sub-second timestamp.
No rehash is in progress or needed.
No error detected.
```


## Testing It Out

Its easy to test out standard recovering - just delete some files from the array
and run **snapraid fix -m**, however it's not so easy for simulated corrupted
files that the scrub operation would find.

To do that there's a script included here:   
**generate_corrupted_file.sh**

This can be used to do just that. It creates a tiny text file, syncs the array
then edits the file but corrupts the timestamps so it doesn't look like it's
changed to SnapRAID, as such a scrub operation will find it.

**NOTE: Don't try using the above script if you don't know what you're doing**

That's it - hopefully this is of use to someone.

