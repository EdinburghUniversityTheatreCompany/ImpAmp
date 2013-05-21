require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'json'

class ImpAmpServer < Sinatra::Base

  configure do
    enable :logging, :dump_errors, :raise_errors
  end

  get '/impamp_server.json' do
    cache_control :public, :"no-cache", :max_age => 0
    send_file 'impamp_server.json'
  end

  post '/pad/:page_no/:key' do |page_no, key|
    key = "." if key == "period"
    key = "/" if key == "slash"

    data = JSON.parse( IO.read('impamp_server.json') )

    pages = data["pages"]
    page = pages[page_no] || {}

    pad = JSON.parse(request.body.read)

    page[key]     = pad
    data["pages"][page_no] = page

    lock = File.open('impamp_server.json')
    lock.flock(File::LOCK_EX)
    File.open('impamp_server.json','w+') do |f|
      f.write data.to_json
    end
    lock.flock(File::LOCK_UN)
    lock.close

    return :success
  end

  post '/page/:page_no' do |page_no|
    data = JSON.parse( IO.read('impamp_server.json') )

    pages = data["pages"]
    page = pages[page_no] || {}

    page.merge! JSON.parse(request.body.read)

    data["pages"][page_no] = page

    lock = File.open('impamp_server.json')
    lock.flock(File::LOCK_EX)
    File.open('impamp_server.json','w+') do |f|
      f.write data.to_json
    end
    lock.flock(File::LOCK_UN)
    lock.close

    return :success
  end

  get '/audio/:filename' do |filename|
    send_file "audio/#{filename}"
  end

  post '/audio/:filename' do |filename|
    File.open("audio/#{filename}", "wb+") do |f|
      f.write request.body.read
    end

    return :success
  end

end