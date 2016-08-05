module Umlaut
  module Mirlyn
    class HoldingsClient
      URI_ARGS = {
        host: "mirlyn-aleph.lib.umich.edu",
        path: '/cgi-bin/getHoldings.pl'
      }

      attr_accessor :results

      def initialize(floor_locations)
        @floor_locations = floor_locations
        @results = []
      end

      def get_holdings(keys)
        keys.each do |key|
          uri = URI::HTTP.build(URI_ARGS.merge(query: "id=#{key}"))
          result = JSON.parse(Net::HTTP.get(uri))
          return unless result
          #pp result
          result.each_pair do |id, list|
            list.each do |item|
              item['item_info'].each do |info|
                @results << Holding.new(item.merge('item_info' => info, 'id' => id))
              end
            end
          end
        end
      end
    end
  end
end