module Umlaut
  module Mirlyn
    class Service < ::Opac
      attr_accessor :client

      # Have to override the default here.
      def parse_for_fulltext_links(marc, request)
        eight_fifty_sixes = []
        marc.find_all { | f| '856' === f.tag}.each do | link |
          eight_fifty_sixes << link
        end
        eight_fifty_sixes.each do | link |
          next if link.indicator2.match(/[28]/)
          next unless link['u']
          next if link['u'].match(/(sfx\.galib\.uga\.edu)|(findit\.library\.gatech\.edu)/)
          label = (link['z']||'Electronic Access')
          request.add_service_response(
            :service=>self,
            :key=>label,
            :value_string=>link['u'],
            :service_type_value => 'fulltext'
            )
        end
      end

      def init_bib_client
        @client ||= Umlaut::Mirlyn::MarcClient.new
      end

      def add_link_to_opac(client, request)
        @client.feed.each_entry do |entry|
          request.add_service_response(
            service: self,
            collection_str: entry.title,
            url: entry.id,
            service_type_value: 'holding'
          )
        end
      end

      def check_holdings(holdings, request)

        request.add_service_response(
          service: self,
          display_text: "Problems accessing link",
          url: @client.problem_url,
          service_type_value: 'help'
        )

        request.add_service_response(
          service: self,
          display_text: 'Search in Mirlyn',
          url: @client.holding_search_url,
          service_type_value: 'holding_search',
        )

        request.add_service_response(
          service: self,
          display_text: 'Document Delivery',
          url: @client.document_delivery_url,
          service_type_value: 'document_delivery',
        )
return
        return if holdings.empty?
        holdings.each do |holding|

          collection_str = holding.location_str.dup
          collection_str << " - " + holding.collection_str unless holding.collection_str.empty?

          call_number = holding.call_no
          call_number = holding.source if call_number.nil? || call_number.empty?


          request.add_service_response(
            service: self,
            key: holding.id.dup,
            call_number: call_number,
            url: holding.url,
            notes: holding.notes,
            status: holding.status_str,
            service_type_value: 'holding',
            collection_str: holding.collection_str,
            request_url: holding.request_url,
          )
        end
      end

      #Override the default here.
      def response_url(service_response, http_params)
        service_response.url
      end

      def init_holdings_client
        Umlaut::Mirlyn::HoldingsClient.new(@floor_locations)
      end

      def service_types_generated
        [
          ServiceTypeValue['fulltext'],
          ServiceTypeValue['holding'],
          ServiceTypeValue['help'],
          ServiceTypeValue['subject'],
          ServiceTypeValue['description'],
          ServiceTypeValue['document_delivery'],
          ServiceTypeValue['holding_search'],
          ServiceTypeValue['highlighted_link']
        ]
      end
    end
  end
end