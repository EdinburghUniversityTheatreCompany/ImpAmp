require 'rack'
require './server'

use ImpAmpServer

use Rack::Static, root: "build", urls: %w[/], index: "index.html"

run lambda{ |env| [ 404, { 'Content-Type'  => 'text/html' }, ['404 - page not found'] ] }