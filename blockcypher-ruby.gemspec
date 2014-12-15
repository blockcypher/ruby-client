Gem::Specification.new do |s|
  s.name        = 'blockcypher-ruby'
  s.summary     = 'Blockcypher Ruby SDK'
  s.version     = '0.1.0'
  s.licenses    = ['Apache 2.0']
  s.description = "Ruby library to help you build your crypto application on BlockCypher"
  s.authors     = ["CoinHako", "BlockCypher"]
  s.email       = 'contact@blockcypher.com'
  s.files       = Dir["{spec,lib}/**/*"] + %w(LICENSE README.md)
  s.homepage    = 'http://www.blockcypher.com'

  s.add_runtime_dependency "bitcoin-ruby", ["~> 0.0.5"]
end
