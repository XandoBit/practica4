#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'uri'
require 'pp'
#require 'socket'
require 'data_mapper'
require 'omniauth-oauth2'      
require 'omniauth-google-oauth2'
require 'pry'
require 'erubis'

DataMapper.setup( :default, ENV['DATABASE_URL'] || 
                            "sqlite3://#{Dir.pwd}/my_shortened_urls.db" )


DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true 

require_relative 'model'

DataMapper.finalize

#DataMapper.auto_migrate!
DataMapper.auto_upgrade!

Base = 36
$mail = ""

# Autentificacion con OmniAuth

use OmniAuth::Builder do       
  config = YAML.load_file 'config/config.yml'
  provider :google_oauth2, config['identifier'], config['secret']
end

  
enable :sessions               
set :session_secret, '*&(^#234a)'

get '/' do
  puts "inside get '/': #{params}"
  @list = ShortenedUrl.all(:order => [ :id.asc ], :limit => 20, :mail => $mail)
  # in SQL => SELECT * FROM "ShortenedUrl" ORDER BY "id" ASC
  haml :index
end

get '/auth/:name/callback' do
    @auth = request.env['omniauth.auth']
    $mail = @auth['info'].mail
    @list = ShortenedUrl.all(:order => [ :id.asc ], :limit => 20, :mail => $mail)
  haml :index
end

post '/' do
  puts "inside post '/': #{params}"
  uri = URI::parse(params[:url])
  if uri.is_a? URI::HTTP or uri.is_a? URI::HTTPS then
    begin
      if params[:url_opc] == " "
        #@short_url = ShortenedUrl.first_or_create(:url => params[:url], :url_opc => params[:url_opc], :mail => $mail)
	@short_url = ShortenedUrl.first_or_create(:url => params[:url], :mail => $mail) 
      else
        #@short_url_opc = ShortenedUrl.first_or_create(:url => params[:url], :url_opc => params[:opc_url], :mail => $mail)
	@short_url_opc = ShortenedUrl.first_or_create(:url => params[:url], :url_opc => params[:url_opc], :mail => $mail) # Se guarda la direccion corta
      end
   rescue Exception => e
      puts "EXCEPTION!"
      pp @short_url
      puts e.message
   end
  else
    logger.info "Error! <#{params[:url]}> is not a valid URL"
  end
  redirect '/'
end

get '/:shortened' do
  puts "inside get '/:shortened': #{params}"
  #short_url = ShortenedUrl.first(:id => params[:shortened].to_i(Base), :email => $email) #se usara la id
  short_url = ShortenedUrl.first(:id => params[:shortened].to_i(Base)) # se usara la id
  short_url_opc = ShortenedUrl.first(:url_opc => params[:shortened], :mail => $mail) #se usara el campo url opcional

  if short_url_opc #Si tiene información, entonces devolvera por url_opc
    redirect short_url_opc.url, 301
  else
    redirect short_url.url, 301
  end
end

error do haml :index end
