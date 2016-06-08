module Fluent
  module PluginMixin
    module ChunkJsonStreamer
      # Iterate over records in chunk
      # @since 0.1.0
      # @returns [Array] an array of record objects
      def records
        records = []
        each do |time, record|
          records << record
        end
        records
      end

      # Serialize the chunk to a Json object
      # @since 0.1.0
      # @returns [String] the serialized object
      def to_json_stream
        json_serializer_proc.call(records)
      end

      private

      # Load relevant Json modules and cache the serializing method
      # @since 0.1.0
      # @returns [Method] a proc which serializes to json
      def json_serializer_proc
        @json_packer ||=  begin
                            require 'oj'
                            Oj.default_options = { mode: :compat }
                            Oj.method(:dump)
                          rescue LoadError
                            Yajl.method(:dump)
                          end
      end
    end
  end
end
