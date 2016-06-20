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

      def response_url(service_response, http_params)
        service_response.url
      end

      def init_holdings_client_
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