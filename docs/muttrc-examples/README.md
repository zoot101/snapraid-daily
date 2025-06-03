# Mutt Notes

The script will work just fine without any email functionality,
but in the opinion of the author it isn't much use without it.

The author has used **mutt** for many years with success
to send emails. The script requires a muttrc file which will
contain all the settings to allow mutt to send emails.

Two configurations are shown below. One for Gmail which works through
the use of "App Passwords" which are simple to configure. This is the
preferred option.

A 2nd configuration is shown for outlook.com. However, this is more
complicated as it requires calling a hook script to handle the oauth2
protocol required. The author has not been able to get app passwords
working with outlook.

The author would like to add more sample configurations here in the future,
but alternative methods of notifications will be explored via hook
scripts in the future.

# Sample Configuration 1 - Gmail via App Passwords

A sample configuration here is provided that works with **Gmail**
which should be easy enough to set up with other providers
also. See the **muttrc_gmail_app_pws** file in this directory.

Note that 2FA is required to be enabled in your Gmail account,
one will then have the option to create app passwords which
can be specified directly in the **muttrc** file.

This muttrc works well for the author - change the password and
email from **server@gmail.com** to the email you want to use and
app password generated via the gmail account page.
 
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
set editor = "nano"
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

This method is more involved, but does have certain advantages.

Mutt supports Oauth2 but requires a hook script to accomplish it.

A requirement of the mutt\_oauth2 hook that is
needed to get it to work with Outlook is that it wants to encrypt
the token file.

This is good for security but kind of a nuisance for me,
as this account is only going to be used for sending
notification emails so if its comprimised,
I don't really care and will just create a new one.

This is just the authors viewpoint of course.

## Step 1 - Create a Special Directory for the mutt config

Lets say we want the muttrc configuration in **/Appdata/server/mutt**. It is possible to work out of
**/home**, but I rather keep that seperate to allow the use of systemd hardening etc.

Start off by creating a directory in the mutt directory for gpg to work out of, and creating a
keypair. Make sure to generate the key pair without a password so the main script can call it
without any input from the user.

```bash
mkdir /Appdata/server/mutt/.gpg/
gpg --homedir /Appdata/server/mutt/.gpg/ --full-generate-key
```

## Step 2 - Download the Hook Script and Configure It

Now download the hook script for mutt from here, and make it executable.

```bash
wget https://gitlab.com/muttmua/mutt/-/raw/master/contrib/mutt_oauth2.py
chmod +x mutt_oauth2.py
```

Unfortunately the script needs to be edited directly. I'm not proficient in python,
but editing it is rather easy.

Find the lines near the top that start with ENCRYPTION\_PIPE and DECRYPTION\_PIPE, and
change them to look like this. They are near the top of the script just where the comments end.
The --home-dir and "/Appdata/server/mutt/.gpg/" can be
omitted if one is happy to have gpg work out of the home directory.

```bash
ENCRYPTION_PIPE = ['gpg', '--homedir', '/Appdata/server/mutt/.gpg/', '--encrypt', '--recipient', 'example@outlook.com']
DECRYPTION_PIPE = ['gpg', '--homedir', '/Appdata/server/mutt/.gpg/', '--decrypt']
```

Next in the registrations section under "microsoft", change the
**client_id** parameter to look like this:   

```bash
'client_id': '9e5f94bc-e8a4-4e73-b8be-63364c29d753',
```

The above list of character is important. It is the client ID for Thunderbird, I'm not
sure if there is one for mutt. That is all that is needed to be changed.

## Step 3 - Generate the Token

Call the now edited hook script like so to generate the token file:

```bash
./mutt_oauth2.py ./.tokens/example.outlook.token --verbose --authorize
```

Type microsoft and devicecode. I have not been able to get the "authcode" or "localhostauthcode" working.

Follow the instructions to visit the URL displayed in a browser and enter the code. Then login, the
process should complete automatically and generate a token file correctly.

## Step 4 - Generate a muttrc file

Then create a muttrc file. This config works for the author:   

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
set editor = "nano"
set charset = "utf-8"
set record = ''

# Puth the path to the edited python script below along with the
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

If the token file is to expire, delete the token file and call the mutt\_oauth2.py script again.

```bash
rm ./.tokens/example.outlook.com.token
./mutt_oauth2.py ./.tokens/example.outlook.token --verbose --authorize
```

If the above works, the muttrc file is ready for use with the main script.

# References

* https://people.math.ethz.ch/~mmarcio/mutt-oauth2-outlook
* https://www.vanormondt.net/~peter/blog/2021-03-16-mutt-office365-mfa.html
* https://github.com/UvA-FNWI/M365-IMAP?tab=readme-ov-file#step-1-get-a-client-idsecret


