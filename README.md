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

Create an audio directory, and ensure the webserver has read/write access.