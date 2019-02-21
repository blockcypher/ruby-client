Gem::Specification.new do |s|
  s.name        = 'blockcypher-ruby'
  s.summary     = 'Blockcypher Ruby SDK'
  s.version     = '0.2.6'
  s.licenses    = ['Apache 2.0']
  s.description = "Ruby library to help you build your crypto application on BlockCypher"
  s.summary     = "Ruby library to help you build your crypto application on BlockCypher"
  s.authors     = ["CoinHako", "BlockCypher", "meXBT", 'Gem']
  s.email       = 'contact@blockcypher.com'
  s.files       = Dir["{spec,lib}/**/*"] + %w(LICENSE README.md)
  s.homepage    = 'http://www.blockcypher.com'

  s.add_runtime_dependency "bitcoin-ruby", ["~> 0.0.5"]
  s.add_runtime_dependency "ffi"
  s.add_development_dependency "bundler", "~> 1.6"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "pry"
  s.add_development_dependency "activesupport"
  s.add_development_dependency "vcr"
  s.add_development_dependency "webmock"
end
