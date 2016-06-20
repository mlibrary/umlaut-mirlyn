require 'atom'
require 'net/http'

module Umlaut
  module Mirlyn
    class MarcClient
      attr_accessor :results, :feed

      URI_ARGS = {
        host: 'mirlyn.lib.umich.edu',
        path: '/Search/SearchExport'
      }

      PARAMS = {
        page: 0,
        method: 'atom'
      }

      def initialize
        @results = []
        @feed = nil
      end

      def accuracy
        3
      end

      def search_by_referent(rft)
        params = PARAMS.merge(params_from(rft))
        uri = URI::HTTP.build(URI_ARGS.merge(query: params.to_query))
        @feed = Atom::Feed.load_feed(uri)
        return if @feed.entries.length > 5
        @feed.each_entry do |entry|
          @results << get_marc(entry)
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
          bool: []
        }

        unless rft.title.nil?
          params[:type] << 'title'
          params[:lookfor] << rft.title
          params[:bool] << 'AND'
        end

        unless rft.year.nil?
          params[:type] << 'year'
          params[:lookfor] << rft.year
          params[:bool] << 'AND'
        end

        unless rft.isbn.nil?
          params[:type] << 'isn'
          params[:lookfor] << rft.isbn
          params[:bool] << 'AND'
        end

        unless rft.issn.nil?
          params[:type] << 'isn'
          params[:lookfor] << rft.issn
          params[:bool] << 'AND'
        end

        unless rft.metadata['au'].nil?
          params[:type] << 'author'
          params[:lookfor] << rft.metadata['au']
          params[:bool] << 'AND'
        end

        unless rft.metadata['pub'].nil?
          params[:type] << 'publisher'
          params[:lookfor] << rft.metadata['pub']
          params[:bool] << 'AND'
        end

        params
      end
    end
  end
end