# frozen_string_literal: true

require_relative 'exots/version'
require_relative 'exots/runner'
require_relative 'exots/client'
require_relative 'exots/context'

module Exots
  class Error < StandardError; end
  class ProcessError < Error; end
  class RPCError < Error; end
end
