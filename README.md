ImpAmp2
=======

Server Setup
------------

Run:

    bundle install
    middleman build

This will install the necessary rubygems and create the build directory.

Create an impamp_server.json file in the root directory containing:

    {"pages":{}}

Make sure the webserver has read/write access.

Create an `audio` directory, and ensure the webserver has read/write access.

Any rack based server should be used - passenger is probably the easiest - although
if you want pretty collaboration indicators, you'll need to use an evented
webserver, like Thin or Rainbows.

An example Apache config using passenger:

```
<VirtualHost *:80>
    ServerName impamp.bedlamtheatre.co.uk

    # Tell Apache and Passenger where your app's 'public' directory is
    DocumentRoot /var/www/impamp/public

    # Relax Apache security settings
    <Directory /var/www/impamp/public>
      Allow from all
      Options -MultiViews
    </Directory>
</VirtualHost>

```
