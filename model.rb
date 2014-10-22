class ShortenedUrl
  include DataMapper::Resource
 
   property :id, Serial
+  property :idusu, Text 
   property :url, Text
+  property :to, Text
+  
 end
end

