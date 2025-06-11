# Mutt Notes

The script will work just fine without any email functionality,
but in the opinion of the author it isn't much use without it.

The author has used **mutt** for many years with success
to send emails. The script requires a muttrc file which will
contain all the settings to allow mutt to send emails.

Note that it is only sending emails that is required here, no consideration is given
to mutt receiving emails since it is not necessary here.

Three configurations are shown below. The first one is for Gmail which works through
the use of "App Passwords" which are simple to configure. This is the
preferred option for its simplicity.

Added configurations are shown for outlook.com and also gmail. However, these are more
complicated as they require calling a hook script to handle the oauth2
protocol required. The hook script also needs to be edited directly.

Although long term they will probably prove to be
more reliable as some email providers can often disable features like
app passwords. They work by effectively getting mutt to masquerade as
Mozilla Thunderbird (which is widely supported).

The author has not been able to get app passwords working with outlook, it may
be down to the reason that they only seem to list a certain few clients
like old generation Xbox consoles that are intended for use with app passwords
on their website. 

To date, only Gmail has proved reliable for the author with the app password feature.

It is the plan to explore alternative methods of notifications via a custom
notification hook script to **snapraid-daily** in the future.

# Sample Configuration 1 - Gmail via App Passwords

A sample configuration here is provided that works with **Gmail**.
See the **muttrc_gmail_app_pws** file in this directory.

Note that 2FA is required to be enabled in your Gmail account,
one will then have the option to create app passwords which
can be specified directly in the **muttrc** file.

This muttrc works well for the author - change the password and
email from **server@gmail.com** to the email you want to use and
app password generated via the gmail account page. Change the "server.home.lan"
to whatever you want the email to be "from".
 
```bash
set realname = "server.home.lan"
set from = "server@gmail.com"
set use_from = yes
set envelope_from = yes

set smtp_url = "smtps://server@gmail.com@smtp.gmail.com:465/"
set smtp_pass = "long-list-of-characters"

set imap_user = "server@gmail.com"
set imap_pass = "long-list-of-characters"

set folder = "imaps://imap.gmail.com:993"
set spoolfile = "+INBOX"
set ssl_force_tls = yes

bind index G imap-fetch-mail
set editor = "vim"
set charset = "utf-8"
set record = ''
```

See the example in this directory **muttrc_gmail_app_pws**

Note that it's a good idea to test **mutt** out on its own with the generated
**muttrc** file before using it with the script.

To do that, after creating the muttrc file - write up a sample email body in a 
simple text file (for example email-body.txt) and use mutt like so to send a test
email to the desired email.

(In this case example@mail.com)

```bash
mutt -F "/path/to/muttrc/file" -s "Email Subject" "example@mail.com" < "email-body.txt"
```

If the above command is successful at sending the email, then mutt is ready
to use with the script accordingly.

# Sample Configuration 2 - Outlook.com via oauth2

This method is more involved as it uses the more secure Oauth2 protocol, but does have
certain advantages.

Mutt supports Oauth2 but requires a hook script to accomplish it. Thankfully, the team
who develop mutt have provided a python hook script that accomplishes this.

A requirement of the mutt\_oauth2 hook that is
needed to get it to work with Outlook is that it wants to encrypt
the token file.

This is good for security but kind of a nuisance for me,
as this account is only going to be used for sending
notification emails so if its comprimised,
I don't really care and will just create a new one.

This is just the authors viewpoint of course.

(See the notes below on a way to disable the encryption/decryption if desired.)

## Step 1 - Create a Special Directory for the mutt config

Lets say we want the muttrc configuration in **/Appdata/server/mutt**. It is possible to work out of
**/home**, but I rather keep that seperate to allow the use of systemd hardening etc.

Start off by creating a directory in the mutt directory for gpg to work out of, and creating a
keypair. Make sure to generate the key pair without a password so the main script can call it
without any input from the user. This isn't very secure, but the email being used shouldn't
really be a critical email anyway.

```bash
mkdir /Appdata/server/mutt/.gpg/
gpg --homedir /Appdata/server/mutt/.gpg/ --full-generate-key
```

## Step 2 - Download the Hook Script and Configure It

Now download the hook script for mutt from here, and make it executable. This hook script
seems to have been around for quite some time, it works pretty well but there are
some areas where it needs configuration.

```bash
wget https://gitlab.com/muttmua/mutt/-/raw/master/contrib/mutt_oauth2.py
chmod +x mutt_oauth2.py
```

Unfortunately the script needs to be edited directly. I'm not proficient in python,
but editing it is rather easy.

Note there is a sample edited version of the script
in this folder that can be used (mutt\_oauth2\_mf.py), but it does have the encryption/decryption disabled,
so I recommend editing it yourself.

Find the lines near the top that start with ENCRYPTION\_PIPE and DECRYPTION\_PIPE, and
change them to look like this. They are near the top of the script just where the comments end.
The --home-dir and "/Appdata/server/mutt/.gpg/" can be
omitted if one is happy to have gpg work out of the home directory.

```bash
ENCRYPTION_PIPE = ['gpg', '--homedir', '/Appdata/server/mutt/.gpg/', '--encrypt', '--recipient', 'example@outlook.com']
DECRYPTION_PIPE = ['gpg', '--homedir', '/Appdata/server/mutt/.gpg/', '--decrypt']
```

Alternatively, if one wants to disable the encryption and decryption entirely and
just store the token in plain text format, edit the above lines to look like this. This
is NOT recommended of course, but if you don't care about the email account and want
to simplify things, it can be done.

```bash
ENCRYPTION_PIPE = ['cat']
DECRYPTION_PIPE = ['cat']
```

Next in the registrations section under "microsoft", change the
**client_id** parameter to look like this:   

```bash
'client_id': '9e5f94bc-e8a4-4e73-b8be-63364c29d753',
```

The above list of characters is important. It is the client ID for Thunderbird, I'm not
sure if there is one for mutt. That is all that is needed to be changed.

This, in effect causes mutt to masquerade as Thunderbird. Thunderbird's client ID and secrets
are publicly available here:

https://hg-edge.mozilla.org/comm-central/file/tip/mailnews/base/src/OAuth2Providers.sys.mjs

## Step 3 - Generate the Token

Now call the edited hook script like so to generate the token file:

```bash
./mutt_oauth2.py ./.tokens/example.outlook.token --verbose --authorize
```

Type **microsoft** when prompted 1st and then **devicecode** when prompted for the 2nd time, and then finally
the desired email for the last prompt.
 
Then the hook script should show a complicated URL to copy and paste into a browser.

Follow the instructions to visit the URL displayed in a browser and enter the code. Then login and click through
the prompts to allow "Thunderbird" access to your outlook account. Then, all going well, the hook script 
should complete automatically and generate a token file correctly.

This should also all work over an SSH connection.

I prefer the devicecode method as its easier and clearer to use, the
authcode also works. The only thing to remember is that once you follow the online prompts and come
to the end, the required code for the hook script sometimes isn't displayed unless you actually click on the address
bar in the browser.

(I have not been able to get the "localhostauthcode" method working for outlook,
it seems outlook requires a https connection to localhost which the script doesn't provide)

## Step 4 - Generate a muttrc file

Then create a muttrc file. This config works for the author, change the
email to the desired email and the paths if they are different. The "realname"
will show up as who the emails sent are "from", it doesn't have to be one's
actual real name.

```bash
# The realname can be edited
set realname = "server.example.org"
set from = "example@outlook.com"
set use_from = yes
set envelope_from = yes

set smtp_url = "smtp://example@outlook.com@smtp.office365.com:587/"
set imap_user = "example@outlook.com"

set folder = "imaps://outlook.office365.com:993"
set spoolfile = "+INBOX"
set ssl_force_tls = yes

# G to get mail
bind index G imap-fetch-mail
set editor = "vim"
set charset = "utf-8"
set record = ''

# Put the path to the edited python script below along with the
# path the token file generated
set imap_authenticators="xoauth2"
 set imap_oauth_refresh_command="/Appdata/server/mutt/mutt_oauth2.py /Appdata/server/mutt/.tokens/example.outlook.token"
 set smtp_authenticators=${imap_authenticators}
 set smtp_oauth_refresh_command=${imap_oauth_refresh_command}
```

See the example in this directory **muttrc_outlook_oauth2**.

## Step 5 - Test it Out

Then test out a sample email by using mutt.

```bash
echo "This is a test email!" > email_body.txt
mutt -F "/path/to/new/muttrc/created/above" -s Test example@mail.com < email_body.txt"
```

If the above completes, mutt is setup to use outlook.com with the oauth2 function. This has a lot of advantages
as it doesn't require using the app passwords feature, which certain providers can like
to turn off without any notice.

```bash
rm ./.tokens/example.outlook.com.token
./mutt_oauth2.py ./.tokens/example.outlook.token --verbose --authorize
```

If the above works, the muttrc file is ready for use with the main script. Note that it
is possible to start over by simply deleting the token file and calling the hook script
with \--authorize like above again.

# Sample Configuration 3 - Gmail via oauth2

This procedure is very similiar to that of the outlook one covered above. Repeat all of
the steps until it comes to editing the python script (mutt\_oauth2.py), then
follow the below:

## Step 1 - Download the Hook script and configure it

As before the steps are:

```bash
wget https://gitlab.com/muttmua/mutt/-/raw/master/contrib/mutt_oauth2.py
chmod +x mutt_oauth2.py
```

The setup with the gpg key is as above for the outlook example.

The main change comes with the client\_id and client\_secret values that
need to be edited into the hook script. 

Once again the easiest way is to masquerade as Thunderbird using the client\_id
and secret from here. (The client ID and Secret are different for Gmail)

https://hg-edge.mozilla.org/comm-central/file/tip/mailnews/base/src/OAuth2Providers.sys.mjs

Edit the hook script in the google section under registrations
so that the clientID and clientSecret look like this as per the above link.

```bash
clientId: "406964657835-aq8lmia8j95dhl1a2bvharmfk3t1hgqj.apps.googleusercontent.com",
clientSecret: "kSmqreRr0qwBWJgbf5Y-PjSU",
```

## Step 2 - Generate the Token

As before with the outlook example, call the hook script like so:

```bash
./mutt_oauth2.py ./.tokens/example.gmail.token --verbose --authorize
```

The two following options can be used in the hook script below. The authors preference is the
**authcode** method, but both that and the **localhostauthcode** will work.

(The author has not been successful in getting the devicecode with gmail.)

## Method 1 - authcode

It is possible to get the **authcode** option but it requires a further edit to the hook script. In
the google section under registrations that was previously edited to add the client ID and secret,
change the redirect\_uri setting like so:

```bash
'redirect_uri': 'http://localhost:1',
```

The reason for the above change is that in 2022 (I think?), Google stopped supporting the
old redirect uri setting that the hook script uses.

Pick a port that isn't being used (1 is a good choice). 

Now call the hook script as above, type **google** and then **authcode** when prompted.

As before copy and paste the complicated URL into the browser, and follow the prompts. However
this time at the very end, the browser will throw an error on not being able to reach the
redirect uri (in this case http://localhost:1), but the required code is now included in
the address bar as before. Here is an example:

```bash
http://localhost:1/?code=4/0AUJR-x4tGGjOkQ5EyCqx9xy2FdLYBU9rzrUZcCY53NK3k7CfoJpaHS2BATs2Q&scope=https://mail.google.com/
```

Copy and paste the code part from the link above to the terminal running the hook script and it 
should now work. 

## Method 2 - localhostauthcode

Type **google** for the 1st prompt, and **localhostauthcode** for the 2nd, and then the desired
email.
 
Just like with the Outlook example, the hook script will show a complicated url to paste into the browser, do that
and you should be prompted to allow Thunderbird access to your account.

If all goes well, the token should be generated by the hook script without problems. The only
caveat with the **localhostauthcode** method is that it requires the browser to be on the
same machine as what is running the hook script - see below.

### Getting the token on a remote machine (If required)

If there's no GUI or browser on the server (there isn't on mine), this creates a bit of a problem
as the localhostauthcode method requires the browser used to be on the same machine
as is calling the hook script.

There is thankfully a simple way around this if one is using a different machine to
interface with the server - An SSH Tunnel.

To get this to work, follow the steps above until one is prompted to enter a complicated
url into the browser, and have a close look at the url.

Here's an example:

```bash
https://accounts.google.com/o/oauth2/auth?client_id=406964657835-aq8lmia8j95dhl1a2bvharmfk3t1hgqj.apps.googleusercontent.com&scope=https%3A%2F%2Fmail.google.com%2F&login_hint=example%40gmail.com&response_type=code&redirect_uri=http%3A%2F%2Flocalhost%3A35505%2F&code_challenge=XXXXXXXXXXXXXXXXXXXXXXXXX&code_challenge_method=S256
```

Note this part of the above URL, this is what directs the browser to the hook script to
generate the token.

```bash
redirect_uri=http%3A%2F%2Flocalhost%3A35505%2F
```

The number after localhost is the port number to use, in this case **35505**.

So on the machine one is using to interface with the server, open an SSH tunnel like so:
```bash
ssh -i /path/to/ssh/key -L 127.0.0.1:35505:127.0.0.1:35505 user@server-hostname
```

This will create an SSH tunnel from the machine with the browser to the server on the same
port as was in the URL so the the redirect uri part of the above URL will work. Once that
tunnel is opened, one can proceed to paste the complicated URL into the browser, login, approve
access of "Thunderbird" to the account, and the token file should be created by the hook script
as before over the SSH tunnel.

One thing that can be done to simplify creating the tunnel is to edit the hook script
to make the port that is used to always be the same each time the script is called to create
a token.

To do that, edit the following line (~line 185) like so. Just make sure that the
port is not used by somethine else.

```bash
listen_port = s.getsockname()[1]

# Change it to this to make the port permanent
listen_port = 50556
```

## Step 4 - Create a muttrc configuration

Here is a sample configuration, edit the email accordingly and paths to the
edited hook script and token files.

See the example **muttrc_gmail_oauth2** in this directory.

```bash
set realname = "server.home.lan"
set from = "server@gmail.com"
set use_from = yes
set envelope_from = yes

set smtp_url = "smtps://server@gmail.com@smtp.gmail.com:465/"
set imap_user = "server@gmail.com"

set folder = "imaps://imap.gmail.com:993"
set spoolfile = "+INBOX"
set ssl_force_tls = yes

# G to get mail
bind index G imap-fetch-mail
set editor = "vim"
set charset = "utf-8"
set record = ''

#set imap_authenticators="oauthbearer:xoauth2"
set imap_authenticators="oauthbearer"
 set imap_oauth_refresh_command="/Appdata/server/mutt/mutt_oauth2.py /Appdata/server/mutt/.tokens/server.gmail.token"
 set smtp_authenticators=${imap_authenticators}
 set smtp_oauth_refresh_command=${imap_oauth_refresh_command}
```

## Step 5 - Test it Out

Just like with the outlook example, this can be tested out like so:

```bash
echo "This is a test email!" > email_body.txt
mutt -F "/path/to/new/muttrc/created/above" -s Test example@mail.com < email_body.txt"
```

If no errors are encountered and the email is sent, the mutt configuration with
Gmail via oauth2 is ready for use with the main script.

Note that it is possible to start over by simply deleting the token file and calling the hook script
with \--authorize like above again.

# Creating ones own Client ID

It is possible to create one's own Client ID at both google and microsoft, but
the process is involved and beyond the scope of what's considered here. Masquerading
as Thunderbird is much easier and likely to be more reliable.

The below links in the references do talk about this.

# References

* https://gitlab.com/muttmua/mutt/-/blob/master/contrib/mutt_oauth2.py.README   
* https://people.math.ethz.ch/~mmarcio/mutt-oauth2-outlook   
* https://www.vanormondt.net/~peter/blog/2021-03-16-mutt-office365-mfa.html   
* https://github.com/UvA-FNWI/M365-IMAP?tab=readme-ov-file#step-1-get-a-client-idsecret   
* https://www.redhat.com/en/blog/mutt-email-oauth2   

