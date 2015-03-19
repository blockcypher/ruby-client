

module BlockCypher

  V1 = 'v1'

  BTC = 'btc'
  LTC = 'ltc'

  MAIN_NET = 'main'
  TEST_NET = 'test'
  TEST_NET_3 = 'test3'

  class Api

    class Error < RuntimeError ; end

    attr_reader :api_token

    def initialize(version: V1, currency: BTC, network: MAIN_NET, api_token: nil)
      @version = version
      @currency = currency
      @network = network
      @api_token = api_token
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
    #
    
    def push_hex(hex)
      payload = { 'tx' => hex }
      api_http_post('/txs/push', json_payload: payload)
    end

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

    def address_details(address, unspent_only: false)
      api_http_get('/addrs/' + address, query: { unspentOnly: unspent_only } )
    end

    def address_final_balance(address)
      details = address_details(address)
      details['final_balance']
    end

    ##################
    # Events API
    ##################

    def event_webhook_subscribe(url, event,
                                token:nil, hash:nil, address:nil, script:nil)
      payload = {
        url: url,
        event: event,
      }
      payload[:token] = token || @api_token if token || @api_token
      payload[:address] = address if address
      payload[:hash] = hash if hash
      payload[:script] = script if script
      api_http_post('/hooks', json_payload: payload)
    end

    ##################
    # Payments and Forwarding API
    ##################

    def create_payments_forwarding(destination, token, callback = nil)
      payload = {
        destination: destination,
        callback_url: callback,
        token: token
      }
      api_http_post('/payments', json_payload: payload)
    end

    private

    def api_http_call(http_method, api_path, query, json_payload: nil)
      uri = endpoint_uri(api_path, query)

      # Build the connection
      http    = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      # Build the Request
      if http_method == :post
        request = Net::HTTP::Post.new(uri.request_uri)
      elsif http_method == :get
        request = Net::HTTP::Get.new(uri.request_uri)
      else
        raise 'Invalid HTTP method'
      end

      unless json_payload.nil?
        request.content_type = 'application/json'
        request.body = json_payload.to_json
      end

      response = http.request(request)

      # Detect errors
      if response.code == '400'
        raise Error.new(uri.to_s + ' Response:' + response.body)
      end

      # Process the response
      begin
        json_response = JSON.parse(response.body)
        return json_response
      rescue => e
        raise "Unable to parse JSON response #{e.inspect}, #{response.body}"
      end
    end

    def api_http_get(api_path, query: {})
      api_http_call(:get, api_path, query)
    end

    def api_http_post(api_path, json_payload: nil, query: {})
      api_http_call(:post, api_path, query, json_payload: json_payload)
    end

    def endpoint_uri(api_path, query)
      if api_path[0] != '/'
        api_path = "/#{api_path}"
      end
      uri = URI("https://api.blockcypher.com/#{@version}/#{@currency}/#{@network}#{api_path}")
      query[:token] = api_token if api_token
      uri.query = URI.encode_www_form(query)
      uri
    end
  end
end
