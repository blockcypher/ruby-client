module BlockCypher

  V1 = 'v1'

  BTC = 'btc'
  LTC = 'ltc'

  MAIN_NET = 'main'
  TEST_NET = 'test'
  TEST_NET_3 = 'test3'

  class Api

    class Error < RuntimeError ; end

    def initialize(version: V1, currency: BTC, network: MAIN_NET)
      @version = version
      @currency = currency
      @network = network
    end

    ##################
    # Blockchain API
    ##################

    def blockchain_transaction(transaction_hash)
      api_http_get('/txs/' + transaction_hash)
    end

    def blockchain_block(block_index)
      api_http_get('/blocks/' + block_index)
    end

    ##################
    # Transaction API
    ##################

    def send_money(from_address, to_address, satoshi_amount, private_key)

      unless to_address.kind_of? Array
        to_address = [to_address]
      end

      tx_new = transaction_new([from_address], to_address, satoshi_amount)

      transaction_sign_and_send(tx_new, private_key)
    end

    def transaction_new(input_addreses, output_addresses, satoshi_amount)
      payload = {
        'inputs' => [
          {
            addresses: input_addreses
          }
        ],
        'outputs' => [
          {
            addresses: output_addresses,
            value: satoshi_amount
          }
        ]
      }
      api_http_post('/txs/new', json_payload: payload)
    end

    def transaction_sign_and_send(new_tx, private_key)
      key = Bitcoin::Key.new(private_key, nil, compressed = true)
      public_key = key.pub
      signatures = []
      public_keys = []

      new_tx['tosign'].each do |to_sign_hex|
        public_keys << public_key
        to_sign_binary = [to_sign_hex].pack("H*")
        sig_binary = key.sign(to_sign_binary)
        sig_hex = sig_binary.unpack("H*").first
        signatures << sig_hex
      end
      new_tx['signatures'] = signatures
      new_tx['pubkeys'] = public_keys

      res = api_http_post('/txs/send', json_payload: new_tx)

      res
    end

    ##################
    # Address APIs
    ##################

    def address_generate
      api_http_post('/addrs')
    end

    def address_details(address)
      api_http_get('/addrs/' + address)
    end

    def address_final_balance(address)
      details = address_details(address)
      details['final_balance']
    end

    ##################
    # Events API
    ##################

    def event_webhook_subscribe(url, filter, token = nil)
      payload = {
        url: url,
        filter: filter,
        token: token
      }
      api_http_post('/hooks', json_payload: payload)
    end

    ##################
    # Payments and Forwarding API
    ##################

    def create_forwarding_address(destination, token, callback_url: nil, enable_confirmations: false)
      payload = {
        destination: destination,
        callback_url: callback_url,
        token: token,
        enable_confirmations: enable_confirmations
      }
      api_http_post('/payments', json_payload: payload)
    end

    alias :create_payments_forwarding :create_forwarding_address

    def list_forwarding_addresses(token)
      api_http_get("/payments?token=#{token}")
    end

    private

    def api_http_call(http_method, api_path, json_payload: nil)
      uri = endpoint_uri(api_path)
      JSON.load RestClient::Request.execute :method => http_method, :url => uri, :payload => json_payload.to_json, :ssl_version => 'SSLv23'
    end

    def api_http_get(api_path)
      api_http_call :get, api_path
    end

    def api_http_post(api_path, json_payload: nil)
      api_http_call :post, api_path, json_payload: json_payload
    end

    def endpoint_uri(api_path)
      if api_path[0] != '/'
        api_path += '/' + api_path
      end
      'https://api.blockcypher.com/' + @version + '/' + @currency + '/' + @network + api_path
    end

  end
end
