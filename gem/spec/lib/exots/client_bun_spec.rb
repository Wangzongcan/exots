# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Exots::Client do
  describe 'Integration with Bun' do
    # Adjust path to fixtures relative to this file or use absolute
    let(:script_path) { File.expand_path('../../../../npm/examples/bun_server.ts', __dir__) }
    let(:tmp_dir) { Dir.mktmpdir('exots-spec-bun-') }
    let(:socket_path) { File.join(tmp_dir, 'rpc.sock') }
    let(:pid_path) { File.join(tmp_dir, 'server.pid') }

    # Disable auto_stop to avoid accumulation of at_exit hooks during tests
    let(:client) do
      described_class.new(
        script_path: script_path,
        socket_path: socket_path,
        pid_path: pid_path,
        runner: Exots::Runner::Bun,
        auto_stop: false
      )
    end
    let(:context) { client.start }

    after do
      client.stop
      FileUtils.rm_rf(tmp_dir) if File.directory?(tmp_dir)
    end

    it 'can spawn a Bun process and call a simple method' do
      result = context.call('ping')
      expect(result).to eq('pong')
    end

    it 'can pass parameters' do
      result = context.call('echo', msg: 'hello bun')
      expect(result).to eq('hello bun')

      sum = context.call('add', a: 10, b: 20)
      expect(sum).to eq(30)
    end

    it 'can pass multiple parameters' do
      sum = context.call('sum', 10, 20)
      expect(sum).to eq(30)
    end
  end
end
