module Umlaut
  module Mirlyn
    class Service < ::Opac
      attr_accessor :client

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
        return if holdings.empty?
        holdings.each do |holding|
          #@record_attributes[holding.id][:holdings] = holding
          collection_str = holding.location_str.dup
          collection_str << " - " + holding.collection_str unless holding.collection_str.empty?

          call_number = holding.call_no
          call_number = holding.source if call_number.nil? || call_number.empty?
          request.add_service_response(
            service: self,
            key: holding.id.dup,
            call_number: call_number,
            value_string: 'value string',
            #url: holding.info_link,
            url: holding.url,
            notes: holding.notes,
            content: 'content',
            #value_string: holding.location_str.dup,
            #value_alt_string: holding.call_no.dup,
            #value_text: holding.status_str.dup,
            status: holding.status_str,
            display_text: "Display Text",
            service_type_value: 'holding',
            collection_str: holding.collection_str,
            request_url: holding.request_url,
            #call_number: holding.call_no,
          )
          pp holding
        end
      end

      #Override the default here.
      def response_url(service_response, http_params)
        service_response.url
      end

      def init_holdings_client
        Umlaut::Mirlyn::HoldingsClient.new
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