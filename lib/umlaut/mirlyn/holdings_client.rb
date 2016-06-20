module Umlaut
  module Mirlyn
    class HoldingsClient
      URL = 'http://mirlyn.lib.umich.edu/Search/SearchExport'

      attr_accessor :results

      def initialize
        @results = []
      end

      def get_holdings(keys)
      end
    end
  end
end