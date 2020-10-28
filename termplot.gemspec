require_relative 'lib/termplot/version'

Gem::Specification.new do |spec|
  spec.name          = "termplot"
  spec.version       = Termplot::VERSION
  spec.authors       = ["Martin Nyaga"]
  spec.email         = ["nyagamartin72@gmail.com"]

  spec.summary       = %q{Plot time series charts in your terminal}
  spec.description   = %q{Plot time series charts in your terminal}
  spec.homepage      = "https://github.com/Martin-Nyaga/termplot"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Martin-Nyaga/termplot" 
  spec.metadata["changelog_uri"] = "https://github.com/Martin-Nyaga/termplot" 

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_runtime_dependency "ruby-termios", "~> 1.0"
end
