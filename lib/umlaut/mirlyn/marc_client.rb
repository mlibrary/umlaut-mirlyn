require 'atom'
require 'net/http'

module Umlaut
  module Mirlyn
    class MarcClient
      attr_accessor :results, :feed

      PARAMS = {
        page: 0,
        method: 'atom'
      }

      AND   = 'AND'
      ISSN  = 'isn'
      ISBN  = 'isn'
      YEAR  = 'year'
      TITLE = 'title_starts_with'
      AUTHOR = 'author'
      PUBLISHER = 'publisher'

      def initialize(help, holding_feed, holding_search, document_delivery)
        @help = help
        @holding_feed = holding_feed
        @holding_search = holding_search
        @document_delivery = document_delivery
        @results = []
        @feed = nil
        @rft = nil
      end

      def accuracy
        3
      end

      def problem_url
        query = @help[:query].merge(
          LinkModel: 'unknown',
          DocumentID: 'http://mgetit.lib.umich.edu/?' + @rft.to_context_object.to_hash.to_query
        )
        URI::HTTP.build(@help.merge(query: query.to_query)).to_s
      end

      def document_delivery_url
        URI::HTTP.build(@document_delivery.merge(query: version_01_params.to_query)).to_s
      end

      def version_01_params
        params = {}
        params[:aufirst] = @rft.metadata['au']
        params[:title]  = @rft.title
        params[:year]   = @rft.year
        params[:issn]   = @rft.issn
        params[:isbn]   = @rft.isbn
        params[:genre]  = @rft.metadata['genre']
        params
      end

      def holding_search_url
        params = PARAMS.merge(params_from(@rft))
        URI::HTTP.build(@holding_search.merge(query: params.to_query)).to_s
      end


      def search_by_referent(rft)
        @rft ||= rft
        params = PARAMS.merge(params_from(rft))
        uri = URI::HTTP.build(@holding_feed.merge(query: params.to_query))
        begin
          @feed = Atom::Feed.load_feed(uri)
          @feed.each_entry do |entry|
            @results << get_marc(entry)
          end
        rescue LibXML::XML::Error => e
          #pp e
          #pp uri.to_s
          #pp @feed
           # Maybe log the error if we want.
        end
      end

      private
      def get_marc(entry)
        Net::HTTP.get(URI(entry.id + '.xml'))
      end

      def params_from(rft)
        params = {
          type: [],
          lookfor: [],
        }

        # genres: journal, book, conference, article,
        #         preprint, proceeding, bookitem
        # in rft: atitle, title, issn, isbn, year, volume
        # in rft.metadata: Anything else

        if rft.metadata['genre'] == 'book'
          params[:'fqor-format'] = ['Book']
          if !rft.metadata['btitle'].nil?
            params[:type] << TITLE
            params[:lookfor] << rft.metadata['btitle']
          elsif !rft.title.nil?
            params[:type] << TITLE
            params[:lookfor] << rft.title
          end
        elsif rft.metadata['genre'] == 'article'
          params[:'fqor-format'] = ['Journal', 'Newspaper', 'Serial']
          if !rft.metadata['jtitle'].nil?
            params[:type] << TITLE
            params[:lookfor] << rft.metadata['jtitle']
          elsif !rft.title.nil?
            params[:type] << TITLE
            params[:lookfor] << rft.title
          end
        else
          unless rft.title.nil?
            params[:type] << TITLE
            params[:lookfor] << rft.title
          end
        end

        unless rft.year.nil?
          params[:'fqor-publishDateTrie'] = [rft.year]
        end

        unless rft.isbn.nil?
          params[:type] << ISBN
          params[:lookfor] << rft.isbn
        end

        unless rft.issn.nil?
          params[:type] <<  ISSN
          params[:lookfor] << rft.issn
        end

        author = rft.metadata['au'] || "#{rft.metadata['aulast']}, #{rft.metadata['aufirst']}".strip
        unless author.nil? || author.empty? || author == ','
          params[:type] << AUTHOR
          params[:lookfor] << author
        end

        #unless rft.metadata['pub'].nil?
        #  params[:type] << PUBLISHER
        #  params[:lookfor] << rft.metadata['pub']
        #end
        params
      end
    end
  end
end