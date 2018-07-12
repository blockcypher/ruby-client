module BlockCypher

  V1 = 'v1'

  BTC = 'btc'
  LTC = 'ltc'
  DOGE = 'doge'
  BCY= 'bcy'

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

    def blockchain_unconfirmed_tx
      api_http_get('/txs')
    end

    def blockchain_transaction(transaction_hash, **params)
      api_http_get('/txs/' + transaction_hash, query: params)
    end

    def blockchain_block(block_index, params)
      api_http_get('/blocks/' + block_index, query: params)
    end

    def blockchain
      api_http_get('')
    end

    ##################
    # Faucet API
    ##################

    def faucet(address, amount)
      payload = { 'address' => address, 'amount' => amount }
      api_http_post('/faucet', json_payload: payload)
    end

    ##################
    # Transaction API
    ##################

    def decode_hex(hex)
      payload = { 'tx' => hex}
      api_http_post('/txs/decode', json_payload: payload)
    end

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
      pubkey = pubkey_from_priv(private_key)
      # Make array of pubkeys matching length of 'tosign'
      new_tx['pubkeys'] = Array.new(new_tx['tosign'].length) { pubkey }
      # Sign the 'tosign' array
      new_tx['signatures'] = signer(private_key, new_tx['tosign'])
      api_http_post('/txs/send', json_payload: new_tx)
    end

    def pubkey_from_priv(private_key)
      key = Bitcoin::Key.new(private_key, nil, compressed = true)
      key.pub
    end

    def signer(private_key, tosign)
      key = Bitcoin::Key.new(private_key, nil, compressed = true)
      signatures = []

      tosign.each do |to_sign_hex|
        to_sign_binary = [to_sign_hex].pack("H*")
        sig_binary = key.sign(to_sign_binary)
        sig_hex = sig_binary.unpack("H*").first
        signatures << sig_hex
      end

      return signatures
    end

    def transaction_new_custom(payload)
      # Build payload yourself, for custom transactions
      api_http_post('/txs/new', json_payload: payload)
    end

    def transaction_send_custom(payload)
      # Send TXSkeleton payload yourself, for custom transactions
      # You may need to sign your data using another library, like Bitcoin
      api_http_post('/txs/send', json_payload: payload)
    end

    def tx_confidence(tx_hash)
      api_http_get('/txs/' + tx_hash + '/confidence')
    end

    ##################
    # Microtx API
    ##################

    # This method sends private key to server
    def microtx_from_priv(private_key, to_address, value_satoshis)
      payload = {
        from_private: private_key,
        to_address: to_address,
        value_satoshis: value_satoshis
      }
      api_http_post('/txs/micro', json_payload: payload)
    end

    # This method uses public key, signs with private key locally
    def microtx_from_pub(private_key, to_address, value_satoshis)
      pubkey = pubkey_from_priv(private_key)
      payload = {
        from_pubkey: pubkey,
        to_address: to_address,
        value_satoshis: value_satoshis
      }
      micro_skel = api_http_post('/txs/micro', json_payload: payload)
      micro_skel['signatures'] = signer(private_key, micro_skel['tosign'])
      api_http_post('/txs/micro', json_payload: micro_skel)
    end

    ##################
    # Address APIs
    ##################

    def address_generate
      api_http_post('/addrs')
    end

    def address_generate_multi(pubkeys, script_type)
      payload = { 'pubkeys' => pubkeys, 'script_type' => script_type}
      api_http_post('/addrs', json_payload: payload)
    end

    def address_details(address, unspent_only: false, limit: 50,
                        before: nil, after: nil, confirmations: nil,
												omit_wallet_addresses: false, include_confidence:false)
      query = {
        unspentOnly: unspent_only,
        limit: limit,
        omitWalletAddresses: omit_wallet_addresses,
				includeConfidence: include_confidence
      }
      query[:before] = before if before
			query[:after] = after if after

      api_http_get('/addrs/' + address, query: query )
    end

    def address_balance(address, omit_wallet_addresses: false)
      query = { omitWalletAddresses: omit_wallet_addresses }
      api_http_get('/addrs/' + address + '/balance', query: query)
    end

    def address_final_balance(address, omit_wallet_addresses: false)
      details = address_balance(address,
                                omit_wallet_addresses: omit_wallet_addresses)
      details['final_balance']
    end

    def address_full_txs(address, limit: 10, before: nil, after: nil,
												 include_hex: false, omit_wallet_addresses: false, include_confidence:false)
      query = {
        limit: limit,
        includeHex: include_hex,
        omitWalletAddresses: omit_wallet_addresses,
				includeConfidence: include_confidence
      }
      query[:before] = before if before
      query[:after] = after if after

      api_http_get("/addrs/#{address}/full", query: query)
    end

    ##################
    # Wallet API
    ##################

    def wallet_create(name, addresses)
      payload = { 'name' => name, 'addresses' => Array(addresses)}
      api_http_post('/wallets', json_payload: payload)
    end

    def wallet_get(name)
      api_http_get('/wallets/' + name)
    end

    def wallet_add_addr(name, addresses, omit_wallet_addresses: false)
      payload = { 'addresses' => Array(addresses) }
      query = { omitWalletAddresses: omit_wallet_addresses }
      api_http_post('/wallets/' + name + '/addresses',
                    json_payload: payload, query: query)
    end

    def wallet_get_addr(name)
      api_http_get('/wallets/' + name + '/addresses')
    end

    def wallet_delete_addr(name, addresses)
      addrjoin = addresses.join(";")
      api_http_delete('/wallets/' + name + '/addresses', query: { address: addrjoin})
    end

    def wallet_gen_addr(name)
      api_http_post('/wallets/' + name + '/addresses/generate')
    end

    def wallet_delete(name)
      api_http_delete('/wallets/' + name)
    end

    ##################
    # Events API
    ##################

    def event_webhook_subscribe(url, event, options = {})
      payload = {
        url: url,
        event: event,
      }.merge(options)

      api_http_post('/hooks', json_payload: payload)
    end

    def event_webhook_listall
      api_http_get('/hooks')
    end

    def event_webhook_get(id)
      api_http_get('/hooks/' + id)
    end

    def event_webhook_delete(id)
      api_http_delete('/hooks/' + id)
    end

    ##################
    # Payments and Forwarding API
    ##################

    def create_forwarding_address(
      destination,
      callback_url: nil,
      enable_confirmations: false,
      mining_fees_satoshis: nil
    )
      payload = {
        destination: destination,
        callback_url: callback_url,
        enable_confirmations: enable_confirmations,
        mining_fees_satoshis: mining_fees_satoshis,
      }
      api_http_post('/payments', json_payload: payload)
    end

    alias :create_payments_forwarding :create_forwarding_address

    def list_forwarding_addresses
      api_http_get("/payments")
    end

    def delete_forwarding_address(id)
      api_http_delete("/payments/" + id)
    end


    #############
    # Asset API #
    #############

    def generate_asset_address
      api_http_post("/oap/addrs")
    end

    def issue_asset(from_private, to_address, amount)
      api_http_post("/oap/issue", json_payload: {
        from_private: from_private,
        to_address: to_address,
        amount: amount
      })
    end

    def transfer_asset(asset_id, from_private, to_address, amount)
      api_http_post("/oap/#{asset_id}/transfer", json_payload: {
         from_private: from_private,
         to_address: to_address,
         amount: amount
      })
    end

    def asset_txs(asset_id)
      api_http_get("/oap/#{asset_id}/txs")
    end

    def asset_address(asset_id, oap_address)
      api_http_get("/oap/#{asset_id}/addrs/#{oap_address}")
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
      elsif http_method == :delete
        request = Net::HTTP::Delete.new(uri.request_uri)
      else
        raise 'Invalid HTTP method'
      end

      unless json_payload.nil?
        request.content_type = 'application/json'
        request.body = json_payload.to_json
      end

      response = http.request(request)
      response_code = response.code.to_i

      # Detect errors/return 204 empty body
      if response_code >= 400
        raise Error.new(uri.to_s + ' Response:' + response.body)
      elsif response_code == 204
        return nil
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

    def api_http_delete(api_path, query: {})
      api_http_call(:delete, api_path, query)
    end

    def endpoint_uri(api_path, query)
      uri = URI("https://api.blockcypher.com/#{@version}/#{@currency}/#{@network}#{api_path}")
      query[:token] = api_token if api_token
      uri.query = URI.encode_www_form(query) unless query.empty?
      uri
    end
  end
end
