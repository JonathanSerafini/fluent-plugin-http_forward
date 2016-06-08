require 'fluent/plugin/output'
require 'fluent/plugin_mixin/chunk_json_streamer'

module Fluent
  module Plugin
    class HttpForwardOutput < Output
      Fluent::Plugin.register_output('http_forward', self)
      helpers :timer

      # http target parameters
      # - url: the URL to upload to, ex.: http://iamateacup:8080/path/%{tag}
      #        the URI may contain the %{tag} pattern which will be replaced
      # - verb: the HTTP verb to use 
      config_param :url,    :string
      config_param :verb,   :string,  :default => :post,
                                      :list => %w(put post)

      # an optional Content-Type header override, this may be unset and will be
      # automatically detected based on the serializing format
      config_param :content_type, :string, :default => nil

      # http authentication parameters
      config_section :authentication, :init => true, :multi => false do
        config_param :method,   :string, :default => nil, :list => %(basic)
        config_param :username, :string, :default => nil
        config_param :password, :string, :default => nil, :secret => true
      end

      # output serializing format
      config_section :format, :init => true, :multi => false do
        config_param :@type, :string, :default => "json",
                                      :list => %w(msgpack json)
      end

      # Initialize new output plugin
      # @since 0.1.0
      # @return [NilClass]
      def initialize
        super
        require 'http'
      end

      # Initialize attributes and parameters
      # @since 0.1.0
      # @return [NilClass]
      def configure(config)
        super

        configure_params(config)
      end

      # Configure plugin parameters
      # @since 0.1.0
      # @return [NilClass]
      def configure_params(config)
        unless config.key?("content_type")
          @content_type = case @format['@type']
            when 'json' then 'application/json'
            when 'msgpack' then 'application/x-msgpack'
            else nil
            end
        end
      end

      # Prepare the plugin event loop
      # @since 0.1.0
      # @return [NilClass]
      def start
        super
        start_connection
      end

      # Prepare the HTTP client object which provides a baseline for future
      # request objects. 
      # @since 0.1.0
      # @return [HTTP::Client]
      def start_connection
        @connection = HTTP::Client.new(
          :headers => @headers
        )

        if @authentication['method']
          @connection = @connection.basic_auth(
            :user => @authentication['username'],
            :pass => @authentication['password']
          )
        end
     
        if @content_type
          @connection = @connection.headers(
            'Content-Type' => @content_type
          )
        end

        @connection
      end

      # Tear down the plugin
      # @since 0.1.0
      # @return [NilClass]
      def shutdown
        @connection.close
        super
      end

      # Enforce the usage of the MsgPack streaming method internally so as to
      # ensure that we have a consistent buffering mechanism.
      # @since 0.1.0
      # @return [NilClass]
      def execute_chunking(tag, es, enqueue: false)
        return handle_stream_with_standard_format(tag, es, enqueue: enqueue)
      end

      # Format the URL for a given request, and optionally replace the tag
      # placerholder in the URI.
      # @since 0.1.0
      # @return [String] the url 
      def format_url(tag, time, data)
        @url.sub(/%{tag}/, tag)
      end

      # Format the Headers for a given request.
      # @since 0.1.0
      # @return [Hash] the header hash
      def format_headers(tag, time, data)
        @headers
      end

      # Format the Body for a given request depending on the Serializing
      # format. 
      # @since 0.1.0
      # @return [String] the request body
      def format_body(tag, time, chunk)
        case @format["@type"]
        when "json"
          chunk.extend Fluent::PluginMixin::ChunkJsonStreamer
          serializer_proc = chunk.method(:to_json_stream)
        else
          serializer_proc = chunk.method(:to_msgpack_stream)
        end

        body = serializer_proc.call
      end

      # Upload the request body to the remote end point
      # @since 0.1.0
      # @return [Response] the HTTP response object
      def upload(tag, time, content)
        headers = format_headers(tag, nil, content)
        url = format_url(tag, nil, content)

        @connection.request(@verb, url, body: content, headers: headers)
      end

      # Process a chunk of records synchronously, committing successful 
      # uploads and re-queueing failures.
      # @since 0.1.0
      # @return [Nil]
      def write(chunk)
        tag = chunk.metadata.tag
        content = format_body(tag, nil, chunk)

        response = upload(tag, nil, content)

        if response.code <= 299
          commit_write(chunk.unique_id)
        else
          @log.warn "failed to flush buffer", code: response.code
        end
      end

      # Process a chunk of records asynchronously, committing successful 
      # uploads and re-queueing failures.
      # @since 0.1.0
      # @return [Nil]
      def try_write(chunk)
        write(chunk)
      end
    end
  end
end
