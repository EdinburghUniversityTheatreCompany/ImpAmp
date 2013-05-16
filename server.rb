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
    pad  = page[key] || {}

    pad[:name]      = params[:name]
    pad[:filename]  = params[:filename]
    pad[:filesize]  = params[:filesize]
    pad[:updatedAt] = params[:updatedAt]

    page[key]     = pad
    data["pages"][page_no] = page

    File.open('impamp_server.json','wb+') do |f|
      f.write data.to_json
    end

    return :success
  end

  delete '/pad/:page_no/:key' do |page_no, key|
    key = "." if key == "period"
    key = "/" if key == "slash"

    data = JSON.parse( IO.read('impamp_server.json') )

    pages = data["pages"]
    page = pages[page_no]

    pad  = page[key] || {}

    pad[:name]      = nil
    pad[:filename]  = nil
    pad[:filesize]  = nil
    pad[:updatedAt] = Time.now.to_i * 1000

    page[key]     = pad
    data["pages"][page_no] = page

    File.open('impamp_server.json','wb+') do |f|
      f.write data.to_json
    end

    return :success
  end

  post '/page/:page_no' do |page_no|
    data = JSON.parse( IO.read('impamp_server.json') )

    pages = data["pages"]
    page = pages[page_no] || {}

    page[:name]      = params[:name]
    page[:updatedAt] = params[:updatedAt]

    data["pages"][page_no] = page

    File.open('impamp_server.json','wb+') do |f|
      f.write data.to_json
    end

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