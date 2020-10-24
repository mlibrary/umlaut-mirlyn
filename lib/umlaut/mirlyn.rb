require 'umlaut'
require 'umlaut/mirlyn/version'
require 'umlaut/mirlyn/marc_client'
require 'umlaut/mirlyn/library_search'
require 'umlaut/mirlyn/holding'
require 'umlaut/mirlyn/holdings_client'
if defined?(Rails)
  require 'umlaut/mirlyn/railtie'
end

module Umlaut
  module Mirlyn
  end
end
