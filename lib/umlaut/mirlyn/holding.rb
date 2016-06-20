module Umlaut
  module Mirlyn
    class Holding
      attr_accessor :id, :location_str, :collection_str, :call_no,
        :copy_str, :status_str, :coverage_str, :notes,
        :identifier, :url, :info_link, :barcode, :source

      MIRLYN_BASE = 'http://mirlyn.lib.umich.edu/Record/'
      HT_BASE     = 'https://catalog.hathitrust.org/Record/'

      def initialize data = {}
        @identifier   = @id = data['id']
        @notes        = data['public_note']
        @call_no      = data['callnumber'] || ''
        @status_str   = data['status']
        #@coverage_str = data['enumcron]']
        @location_str = data['location']
        @collection   = data['collection']
        @collection_str = @location_str
        @info_link = data['info_link']
        @barcode   = data['item_info']['barcode']
        @source    = data['item_info']['source']
        @url = (data['sub_library'] == 'HATHI' ? HT_BASE : MIRLYN_BASE) + @id
        @raw = data
      end

      def request_url
        path = case @status_str
        when 'Building use only'
          'Request'
        when 'Search only (no full text)', 'Available online'
          nil
        else
          'Hold'
        end

        if path && @barcode
          @url + "/#{path}?barcode=#{@barcode}"
        end
      end
    end
  end
end