require 'socket'               # Get sockets from stdlib
require 'uri'
require 'cgi'
require 'timeout'
require 'net/http'
require 'net/https'


Consumer_key = '12483-e2a74088174a17f2872c4d82'
Dirr      = File.expand_path File.dirname(__FILE__)
begin
Token = File.read(Dirr + "/token")  #get the token from file
rescue
Token = 'Error'
end


def start_server
  begin
    timeout(30){ 
      client = MyServer.accept       # Wait for a client to connect
      client.gets  #without this client dies
      response = File.read(Dirr + "/resp.html")  #serve a simple html file for the client
      headers = ["HTTP/1.1 200 OK",
                 "Date: Tue, 14 Dec 2010 10:48:45 GMT",
                 "Server: Ruby",
                 "Content-Type: text/html; charset=iso-8859-1",
                 "Content-Length: #{response.length}\r\n\r\n"].join("\r\n")
      client.puts headers          # Send the header to the client
      client.puts response         #send the response to the client
      # client.close
      resp = get_access() #try and convert request token to access_token via pocket api
      if resp[0] == "200" 
        puts "Connected succesfully as #{resp[1]["username"]}"
        File.open(Dirr + "/token", 'w') { |file| file.write(resp[1]["access_token"]) } #save access_token to file
      else
        puts "Oops, there seems to have been an error"
      end
      MyServer.close
    }
  rescue Timeout::Error => e
    puts "Server is shutting down due to inactivity"
    MyServer.close
    return nil
  end
end

##http post to pocket api
def pocket_api(path,data)
  http = Net::HTTP.new('getpocket.com', 443)
  # http.set_debug_output $stderr  #uncomment for debug data
  http.use_ssl = true
  headers = {
    'Content-Type' => 'application/x-www-form-urlencoded'
  }
  resp, data = http.post(path, data, headers)

  # puts 'Code = ' + resp.code
  # puts 'Message = ' + resp.message
  # resp.each {|key, val| puts key + ' = ' + val}
  data = CGI::parse(data)
  return [resp.code,data]
end

##post url and title to pocket
def post_to_pocket(url,title)
  path = '/v3/add'
  escaped_url = CGI::escape(url)
  escaped_title = CGI::escape(title)
  data = "consumer_key=#{Consumer_key}&access_token=#{Token}&url=#{escaped_url}"
  if title != ""
    data =  data + "title=#{escaped_title}"
  end
  resp = pocket_api(path,data)
  if resp[0] == "200"
    puts "Successfuly posted #{url} to Pocket"
  else
    puts "Something went wrong! Try to login again"
  end
end
## get access token as per PocketAPI
def get_access
  path = '/v3/oauth/authorize'
  data = "consumer_key=#{Consumer_key}&code=#{Token}"
  return pocket_api(path,data)
end

#applescript helper
def applescript(argument)
  case argument
    when "isChrome"
      return `osascript -e 'tell app "System Events" to count processes whose name is "Google Chrome"'`
    when "isSafari"
      return `osascript -e 'tell app "System Events" to count processes whose name is "Safari"'`
    when "chrome"
      url = `osascript -e 'tell application "Google Chrome" to return URL of active tab of front window'`
      title = `osascript -e 'tell application "Google Chrome" to return title of active tab of front window'`
      return [url,title]
    when "safari"
      url = `osascript -e 'tell application "Safari" to return URL of front document'`
      title = `osascript -e 'tell application "Safari" to return name of front document'`
      return [url,title]
  end
end


#output xml helper function, receives array of items
#item is a hash
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

# run script according to arguments
# login will try and login
# post will post the second argument as url and third as title
case ARGV[0]
  when "login"
    MyServer = TCPServer.new(2222)   # Socket to listen on port 2000
    start_server()
  when "post"
    # puts "doing post"
    case 
      when Token == 'Error'
        puts "Please login with pocket first using pocket_login in alfred"
        exit
      when  ARGV[1].match(/chrome|safari/)
        url = applescript(ARGV[1])[0]
        title = applescript(ARGV[1])[1]
      when ARGV[1].match(/http/)
        url = ARGV[1]
        title = ""
      else
        abort('I dunno what todo with that')
    end
    # puts CGI.escape(url)
    post_to_pocket(url,title)
  when "get_options"
    arr = []
    isChrome = applescript("isChrome")
    isSafari = applescript("isSafari")
    isClipboard = URI.extract(`osascript -e "get the clipboard"`).length
    if isChrome.to_i > 0
      title = applescript("chrome")[1]
      arr << {"title" => "Pocket - save url from Chrome",
        "uid" => "chrome",
        "arg" => "chrome",
        "subtitle" => "Post \"#{title.strip}\" to pocket",
      }
    end
    if isSafari.to_i > 0
      title = applescript("safari")[1]
      arr << {
              "title" => "Pocket - save url from Safari",
              "uid" => "safari",
              "arg" => "safari",
              "subtitle" => "Post \"#{title.strip}\" to pocket",
            }
    end
    if isClipboard > 0
      url = URI.extract(`osascript -e "get the clipboard"`)[0]
      arr << {
              "title" => "Pocket - save url from Clipboard",
              "uid" => "clipboard",
              "arg" => url,
              "subtitle" => "Post \"#{url.strip}\" to pocket",
            }
    end
    output_xml(arr)
  else
    puts "You gave me #{ARGV} -- I have no idea what to do with that."
end


########## all code below is for my reference only #############

# input = client.gets.split(" ")[1].split('?')[1]
# parsed_input = CGI::parse(input)
# arg = ARGV[0] ||= ""

# array = parsed_input["array[]"].select{|x| x.downcase.include?(arg.downcase)}

# puts '<?xml version="1.0"?><items>'

# array.each {
  # |name, index| puts "<item uid=\"#{name}\" arg=\"#{name}\">
      # <title>#{name}</title>
      # <icon>icon.png</icon>
      # <subtitle>Play \"#{name}\" playlist on Pandora</subtitle>
      # </item>"
# }
# puts '</items>'

  # # puts input
  # resp = 'ok'
  # headers = ["HTTP/1.1 200 OK",
  #            "Date: Tue, 14 Dec 2010 10:48:45 GMT",
  #            "Server: Ruby",
  #            "Content-Type: text/html; charset=iso-8859-1",
  #            "Content-Length: #{resp.length}\r\n\r\n"].join("\r\n")
  # client.puts headers          # Send the time to the client
  # client.puts resp
  # client.close                 # Disconnect from the client
  # server.close                 # Close the server, we don't need it anymore
# }

