# Mutt Notes

The script will work just fine without any email functionality,
but in the opinion of the author it isn't much use without it.

The author has used **mutt** for many years with success
to send emails. The script requires a muttrc file which will
contain all the settings to allow mutt to send emails.

# Sample Configuration

A sample configuration here is provided that works with **Gmail**
which should be easy enough to set up with other providers
also.

Note that 2FA is required to be enabled in your Gmail account,
one will then have the option to create app passwords which
can be specified directly in the **muttrc** file.

Note that it's a good idea to test **mutt** out on its own with the generated
**muttrc** file before using it with the script.

To do that, write up a sample email body in a simple text file (for example
email-body.txt) and use mutt like so to send a test email to the desired email.
(In this case example@mail.com)
```bash
mutt -F "/path/to/muttrc/file" -s "Email Subject" "example@mail.com" < "email-body.txt"
```
If the above command is successful at sending the email, then mutt is ready
to use with the script accordingly.
