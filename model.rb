class ShortenedUrl
  include DataMapper::Resource
 
   property :id, Serial
   property :idusu, Text 
   property :url, String
   property :to, String
 
end

