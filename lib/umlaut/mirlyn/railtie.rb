module Umlaut
  module Mirlyn
    class Railtie < Rails::Railtie

      initializer 'umlaut_mirlyn.initialize' do
        require File.dirname(__FILE__) + '/service'
      end
    end
  end
end