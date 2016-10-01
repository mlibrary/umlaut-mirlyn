module Umlaut
  module Mirlyn
    class Service < ::Opac
      attr_accessor :client

      def initialize(config)

        @holding_search = {
          'base' => {},
          'label' => 'Holdings Search'
        }
        @help = {
          'base' => {query: {}},
          'label' => 'Help'
        }
        @document_delivery = {
          'base' => {},
          'label' => 'Document Delivery'
        }

        super

        @preempted_by = [
          { 'existing_type' => :disambiguation }
        ]
      end

      def handle(request)
        add_help_link(request)
        add_document_delivery_link(request)
        add_holding_search_link(request)
        #super(request)
      end

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
            service: self,
            key: label,
            value_string: link['u'],
            service_type_value: 'fulltext'
          )
        end
      end

      def add_holding_search_link(request)
        request.add_service_response(
          service: self,
          display_text: @holding_search['label'],
          url: holding_search_url(request),
          service_type_value: 'holding_search'
        )
      end

      def holding_search_url(request)
        rft = request.referent
        params = MarcClient::PARAMS.merge(MarcClient.params_from(rft))
        base = @holding_search['base'].symbolize_keys
        URI::HTTP.build(base.merge(query: params.to_query)).to_s
      end

      def add_help_link(request)
        request.add_service_response(
          service: self,
          display_text: @help['label'],
          url: problem_url(request),
          service_type_value: 'help'
        )
      end

      def problem_url(request)
        rft = request.referent
        base = @help['base'].symbolize_keys
        query = base[:query].merge(
          LinkModel: 'unknown',
          DocumentID: 'http://mgetit.lib.umich.edu/?' + rft.to_context_object.to_hash.to_query
        )
        URI::HTTP.build(base.merge(query: query.to_query)).to_s
      end

      def add_document_delivery_link(request)
        request.add_service_response(
          service: self,
          display_text: @document_delivery['label'],
          url: document_delivery_url(request),
          service_type_value: 'document_delivery',
        )
      end

      def document_delivery_url(request)
        base = @document_delivery['base'].symbolize_keys
        rft = request.referent
        URI::HTTP.build(base.merge(query: version_01_params(rft).to_query)).to_s
      end

      def version_01_params(rft)
        params = rft.metadata.dup
        if params['title'].nil?
          params['title'] = params['jtitle'] || params['btitle']
        end

        if params['aufirst'].nil?
          params['aufirst'] = params['au']
        end
        params
      end

      def init_bib_client
        @client ||= Umlaut::Mirlyn::MarcClient.new(
          @holding_feed['base'].symbolize_keys,
          @help['base'].symbolize_keys,
          @holding_search['base'].symbolize_keys,
          @document_delivery['base'].symbolize_keys
        )
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
          display_text: @holding_search['label'],
          url: @client.holding_search_url,
          service_type_value: 'holding_search',
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
