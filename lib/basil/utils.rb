module Basil
  # Utility functions that are useful across multiple plugins should
  # reside here. They are mixed into the Plugin class.
  module Utils
    # Handles both single and multi-line statements to no one in
    # particular.
    #
    #   says "something"
    #
    #   says do |out|
    #     out << "first line"
    #     out << "second line"
    #   end
    #
    # The two invocation styles can be combined to do a sort of Header
    # and Lines thing when printing tabular data; the first argument
    # will be the first line printed then the rest will be built from
    # your block.
    #
    #   says "here's some data:" do |out|
    #     data.each do |d|
    #       out << d.to_s
    #     end
    #   end
    #
    def says(txt = nil, &block)
      if block_given?
        out = txt.nil? ? [] : [txt]

        yield out

        return says(out.join("\n")) unless out.empty?
      elsif txt
        return Message.new(nil, Config.me, Config.me, txt)
      end

      nil
    end

    # Same usage and behavior as says but this will direct the message
    # back to the person who sent the triggering message.
    def replies(txt = nil, &block)
      if block_given?
        out = txt.nil? ? [] : [txt]

        yield out

        return replies(out.join("\n")) unless out.empty?
      elsif txt
        return Message.new(@msg.from_name, Config.me, Config.me, txt)
      end

      nil
    end

    def forwards_to(new_to)
      Message.new(new_to, Config.me, Config.me, @msg.text)
    end

    def escape(str)
      require 'cgi'
      CGI::escape(str.strip)
    end

    def get_http(options)
      if options.is_a? Hash
        host     = options[:host]
        port     = options[:port]     rescue 80
        username = options[:user]     rescue nil
        password = options[:password] rescue nil
        path     = options[:path]

        secure = port == 443

        # An explicit cert file is needed if run on OSX, provided by the
        # curl-ca-bundle cert package
        cert_file = Config.https_cert_file rescue nil

        require (secure ? 'net/https' : 'net/http')
        net = Net::HTTP.new(host, port)

        if secure
          net.use_ssl = true
          net.ca_file = cert_file if cert_file
        end

        net.start do |http|
          req = Net::HTTP::Get.new(path)
          req.basic_auth(username, password) if username || password
          http.request(req)
        end
      else
        url = options
        require (url =~ /^https/ ? 'net/https' : 'net/http')
        Net::HTTP.get_response(URI.parse(url))
      end
    rescue Exception => ex
      $stderr.puts "error getting http: #{ex}"
      nil
    end

    def get_json(*args)
      require 'json'
      resp = get_http(*args)
      JSON.parse(resp.body) if resp
    rescue Exception => ex
      $stderr.puts "error parsing json: #{ex}"
      nil
    end

    def symbolize_keys(h)
      n = {}
      h.each do |k,v|
        n[k.to_sym] = v
      end

      n
    end
  end
end
