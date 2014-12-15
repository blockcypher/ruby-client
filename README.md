# BlockCypher Ruby Client

Simple Ruby client for the [BlockCypher](http://www.blockcypher.com) API.

## Initializing a client

If you want to use BTC on the main net, which is normally what you want to do, it's as simple as:

    block_cypher = BlockCypher::Api.new

## Setting up payment forwarding

    BlockCypher::Api.new.create_payments_forwarding('your_forwarding_addresss', 'your_token')

## BlockCypher's documentation

For more information check the API docs at:

http://dev.blockcypher.com

## Contributors

Contributions from [CoinHako](http://www.coinhako.com) and [meXBT](https://mexbt.com)