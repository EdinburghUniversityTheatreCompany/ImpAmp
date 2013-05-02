require 'rack'
require './server'

use ImpAmpServer

use Rack::Static, :root => "build", :urls => %w[/]

run lambda { |env|
  [
    200,
    {
      'Content-Type'  => 'text/html',
      'Cache-Control' => 'public, max-age=86400'
    },
    File.open('build/index.html', File::RDONLY)
  ]
}