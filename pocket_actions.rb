require 'net/http'
require 'net/https'
require 'uri'

# postData = Net::HTTP.post_form(URI.parse('https://getpocket.com/v3/oauth/request/'), 
#                                {'consumer_key'=>'12483-e2a74088174a17f2872c4d82','redirect_uri'=>'http://alexw.me'})
# http.use_ssl = true
# puts postData.body

# some globals
Consumer_key = '12483-e2a74088174a17f2872c4d82'
Redirect_uri = 'http://alexw.me'
Dir 		 = File.expand_path File.dirname(__FILE__)

def init
	def request_token
		url = URI.parse('https://getpocket.com/v3/oauth/request/')
		req = Net::HTTP::Post.new(url.path)
		req.set_form_data({'consumer_key'=>Consumer_key,'redirect_uri'=>Redirect_uri})
		http = Net::HTTP.new(url.host, url.port)
		http.use_ssl = true
		response = http.request(req)
		return response.body.split("code=")[1]
	end
	def output_xml(items)
		puts "<?xml version=\"1.0\"?><items>"
		items.each do |item|
			puts "<item uid=\"#{item["uid"]}\" arg=\"#{item["arg"]}\">
		      <title>#{item["title"]}</title>
		      <icon>icon.png</icon>
		      <subtitle>#{item["subtitle"]}</subtitle>
		      </item>"
	  	end
		puts "</items>"	
	end
end

#init the methods
init()  
#request tokens from pocket
token = request_token()
#save token to file
File.open(Dir + "/token", 'w') { |file| file.write(token) }

arr = [{
	'title' => 'Login with Pocket',
	'uid' => 'login',
	'arg' => token,
	'subtitle' => 'Login with Pocket.com (you will be taked to pocket.com)'
}]
# and finally output the xml
output_xml(arr)