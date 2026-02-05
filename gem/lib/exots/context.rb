# frozen_string_literal: true

require 'socket'
require 'json'
require 'securerandom'

module Exots
  class Context
    attr_reader :socket_path

    def initialize(socket_path)
      @socket_path = socket_path
    end

    def call(method, *args)
      id = SecureRandom.uuid

      payload = {
        jsonrpc: '2.0',
        method: method,
        params: args,
        id: id
      }

      response = send_request(payload)
      handle_response(response, id)
    end

    private

    def send_request(payload)
      body = JSON.generate(payload)

      UNIXSocket.open(@socket_path) do |sock|
        sock.write("POST / HTTP/1.1\r\n")
        sock.write("Host: localhost\r\n")
        sock.write("Content-Type: application/json\r\n")
        sock.write("Content-Length: #{body.bytesize}\r\n")
        sock.write("\r\n")
        sock.write(body)

        parse_response(sock)
      end
    rescue Errno::ENOENT, Errno::ECONNREFUSED
      raise Error, "Failed to connect to socket at #{@socket_path}"
    end

    def parse_response(sock)
      status_line = sock.gets
      return nil unless status_line

      status = status_line.split(' ')[1].to_i
      headers = {}

      while (line = sock.gets) && line != "\r\n"
        key, value = line.split(':', 2)
        headers[key.strip.downcase] = value.strip if key
      end

      if status == 204
        return { 'result' => nil } # Notification or empty response
      end

      raise Error, "HTTP Error: #{status}" unless status >= 200 && status < 300

      content_length = headers['content-length']&.to_i
      return nil unless content_length && content_length > 0

      body = sock.read(content_length)
      JSON.parse(body)
    end

    def handle_response(response, _id)
      return nil if response.nil?

      if response.key?('error')
        error = response['error']
        raise RPCError, "#{error['message']} (code: #{error['code']})"
      end

      response['result']
    end
  end
end
