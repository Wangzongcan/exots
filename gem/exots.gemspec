# frozen_string_literal: true

require_relative 'lib/exots/version'

Gem::Specification.new do |spec|
  spec.name = 'exots'
  spec.version = Exots::VERSION
  spec.authors = ['sunteya']
  spec.email = ['sunteya@gmail.com']

  spec.summary = 'A Ruby client for executing JavaScript functions via an IPC bridge.'
  spec.description = 'Exots provides a seamless bridge to spawn Node.js/Bun processes and execute functions via high-performance Unix Domain Sockets.'
  spec.homepage = 'https://github.com/sunteya/exots'
  spec.license = 'ISC'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  # Add LICENSE and README.md manually as they are copied during build
  spec.files += %w[LICENSE README.md]

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'json'
end
