# BlockCypher Ruby Client

Simple Ruby client for the [BlockCypher](http://www.blockcypher.com) API.

## Setup

Simply using rubygems:

    gem install blockcypher-ruby

### For Rails apps

Add this line to your application's Gemfile:

```ruby
gem 'blockcypher-ruby', '~> 0.2.5'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ git clone https://github.com/blockcypher/ruby-client.git
$ cd ruby-client
$ bundle
$ gem build blockcypher-ruby.gemspec
$ gem install blockcypher-ruby-0.2.5.gem
```

## Initializing a client

If you want to use BTC on the main net, which is normally what you want to do, it's as simple as:

    block_cypher = BlockCypher::Api.new

## BlockCypher's documentation

For more information check the API docs at:

http://dev.blockcypher.com

## Development

- Copy `spec/config.yml.sample` to `spec/config.yml` and put your test API token
- `rspec spec`

## Contributors

Contributions from [CoinHako](http://www.coinhako.com) and [meXBT](https://mexbt.com)
