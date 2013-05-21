require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'json'

class ImpAmpCollaboration < Sinatra::Base
  @@connections = []

  get '/c/stream', :provides => 'text/event-stream' do
    stream :keep_open do |out|
      # Prevent frequent reconnects - useful if server doesn't support
      # keep_open.
      out << "retry: 30000\n\n"

      @@connections << out
      out.callback { @@connections.delete(out) }
    end
  end

  post '/c/play' do
    send_message("play", params[:page], params[:key], params[:time])

    return 204
  end

  post '/c/timeupdate' do
    send_message("timeupdate", params[:page], params[:key], params[:time])

    return 204
  end

  post '/c/pause' do
    send_message("pause", params[:page], params[:key], params[:time])

    return 204
  end

  def send_message(type, page, key, time)
    message = {
      type: type,
      page: page,
      key:  key,
      time: time
    }

    @@connections.each do |out|
      out << "data: #{message.to_json}\n\n"
    end
  end
end