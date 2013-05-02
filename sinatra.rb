require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'json'

class ImpAmpServer < Sinatra::Base

  configure do
    enable :logging, :dump_errors, :raise_errors
  end

  get '/impamp_server.json' do
    send_file 'impamp_server.json'
  end

  post '/pads/:page/:key' do |page_no, key|
    data = JSON.parse( IO.read('impamp_server.json') )

    page = data[page_no] || {}
    pad  = page[key] || {}

    pad = JSON.parse(params[:pad])

    page[key]     = pad
    data[page_no] = page

    File.open('impamp_server.json','w') do |f|
      f.write data
    end
  end

  get '/audio/:filename' do |filename|
    send_file "audio/#{filename}"
  end

  post '/audio/:filename' do |filename|
    File.open("audio/#{filename}", "w") do |f|
      f.write request.body.read
    end
  end

end