# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-http_forward"
  spec.version       = "0.1.0"
  spec.authors       = ["Jonathan Serafini"]
  spec.email         = ["jonathan@serafini.ca"]

  spec.summary       = %q{A buffered HTTP batching output for Fluentd}
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/JonathanSerafini/fluent-plugin-http_forward"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency "fluentd", [">= 0.14.0", "< 2"]
  spec.add_runtime_dependency "http", [">= 2.0.0", "< 3.0.0"]
end
