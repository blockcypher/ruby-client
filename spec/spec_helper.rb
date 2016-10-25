require "pry"
require "rspec"
require "yaml"
require "active_support/core_ext/hash/indifferent_access"
require "pathname"
require "blockcypher"

SPEC_DIR = Pathname.new(File.dirname(__FILE__))

Dir[SPEC_DIR.join("support", "**", "*.rb")].each {|f| require f}

CONFIG_FILE = SPEC_DIR.join("config.yml")
CONFIG = YAML.load_file(CONFIG_FILE).with_indifferent_access
