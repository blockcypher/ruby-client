require 'spec_helper'

module BlockCypher

  describe Api, vcr: {record: :once} do
    let(:api) do
      BlockCypher::Api.new({
        api_token: CONFIG[:api_token],
        currency: BlockCypher::BCY,
        network: BlockCypher::TEST_NET,
        version: BlockCypher::V1
      })
    end

    let(:addr1) { api.address_generate }
    let(:addr2) { api.address_generate }
		context '#address_generate' do
			it 'should generate new addresses' do
				expect(addr1["address"]).to be_a(String)
				expect(addr2["address"]).to be_a(String)
			end
		end

    let(:address_1) { addr1["address"].to_s }
    let(:address_1_private_key) { addr1["private"].to_s }

    let(:address_2) { addr2["address"].to_s }
    let(:address_2_private_key) { addr2["private"].to_s }

		context '#faucet' do
			it 'should fund a bcy test address with the faucet' do
				res = api.faucet(address_1, 100000)
				expect(res["tx_ref"]).to be_a(String)
			end
		end

    context '#transaction_new' do
      it 'should call the txs/new api' do
        input_addresses = [address_1]
        output_addresses = [address_2]
        satoshi_value = 20000
        res = api.transaction_new(input_addresses, output_addresses, satoshi_value)
        expect(res["tx"]["hash"]).to be_a(String)
        expect(res["tx"]["hash"].length).to be(64)
      end
    end

    context '#transaction_sign_and_send' do
      it 'should call txs/send api' do
        input_addresses = [address_1]
        output_addresses = [address_2]
        satoshi_value = 10000

        new_tx = api.transaction_new(input_addresses, output_addresses, satoshi_value)
        res = api.transaction_sign_and_send(new_tx, address_1_private_key)
        expect(res["tx"]["hash"]).to be_a(String)
        expect(res["tx"]["hash"].length).to be(64)
      end
    end

    context '#address_final_balance' do
      it 'should get the balance of an address' do
        balance = api.address_final_balance(address_1)
        expect(balance).to be_kind_of Integer
        expect(balance).to be > 0
      end
    end

    context '#create_forwarding_address' do

      it 'creates a payment forward' do
        forward_details = api.create_forwarding_address(address_1)
        expect(forward_details["input_address"]).to be_a(String)
        expect(forward_details["input_address"].length).to be(34) # Ok this isn't strictly true but..
      end

      it 'allows creating a payment forward with options' do
        forward_details = api.create_forwarding_address(address_1, {
          callback_url: "http://test.com/foo",
          enable_confirmations: true,
          mining_fees_satoshis: 20_000,
        })
        expect(forward_details["callback_url"]).to eql("http://test.com/foo")
        expect(forward_details["enable_confirmations"]).to be true
        expect(forward_details["mining_fees_satoshis"]).to be 20_000
      end

      it 'is possible to use the alias create_payments_forwarding' do
        forward_details = api.create_payments_forwarding(address_1)
        expect(forward_details["input_address"]).to be_a(String)
      end

    end

    context '#list_forwarding_addresses' do
      it 'lists all forwading addresses created for a given token' do
        forwarding_addresses = api.list_forwarding_addresses
        expect(forwarding_addresses.first["destination"]).to eql(address_1)
      end
    end

		context '#delete_forwarding_address' do
			it 'deletes all previously created forwarding addresses' do
				forwarding_addresses = api.list_forwarding_addresses
				forwarding_addresses.each{|x| api.delete_forwarding_address(x["id"])}
				forwarding_addresses = api.list_forwarding_addresses
				expect(forwarding_addresses.any? == false)
			end
		end

    describe '#endpoint_uri' do
      it 'should encode query into URI' do
        uri = api.send(:endpoint_uri, '/path', { test: 42 }).to_s
        expect(uri).to match(/\?test=42/)
      end

      it 'should encode @api_token into URI if exists' do
        allow(api).to receive(:api_token) { 'token' }
        uri = api.send(:endpoint_uri, '/path', {}).to_s
        expect(uri).to match(/\?token=token/)
      end
    end

    describe "Asset API" do
      describe "Generate Asset Address" do
        it "should include private, public, oap_address, original_address hashes" do
          res = api.generate_asset_address
          expect(res).to include("private", "public", "oap_address", "original_address")
        end
      end

      describe "Issue Asset" do
        it "should issue asset" do
          asset_address = api.generate_asset_address
          api.faucet(asset_address["original_address"], 1000000)
          res = api.issue_asset(asset_address["private"], asset_address["oap_address"], 1000)

          expect(res).to include(
            "ver",
            "assetid",
            "oap_meta",
            "hash",
            "received",
            "double_spend",
            "inputs",
            "outputs"
          )
        end
      end

      describe "Asset Transfer" do
        it "should transfer asset" do
          asset_address = api.generate_asset_address
          asset_address_to = api.generate_asset_address
          api.faucet(asset_address["original_address"], 100000000)
          asset = api.issue_asset(asset_address["private"], asset_address["oap_address"], 1000)

          puts "waiting asset to been issued"
          begin
            printf("|")
            check_address = api.asset_address(asset["assetid"], asset_address["oap_address"])
            sleep(1)
          end while check_address["n_tx"] == 0

          res = api.transfer_asset(asset["assetid"], asset_address["private"], asset_address_to["oap_address"], 100)
          expect(res).to include("assetid")
        end
      end
    end
  end
end
