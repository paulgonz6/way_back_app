require 'open-uri'
require 'json'
require 'nokogiri'
require 'timeout'

class SearchController < ApplicationController

  def home
    @address = params[:address]
    @limit = params[:count]
    @starting_from = params[:from]

    raw_url = "http://web.archive.org/cdx/search/cdx?url=www.#{@address}&output=json&limit=#{@limit}&collapse=timestamp:6&from=#{@starting_from}"
    address_url_safe = URI.encode(raw_url)
    open(address_url_safe)

    # PARSES DATA
    raw_output = open(address_url_safe).read
    @parsed_data_address = JSON.parse(raw_output)
    
    # FORMATS DATA INTO HASH
    @all_data = []

    @parsed_data_address.each do |archive|
      hash_of_each_call = {}
        archive.each_with_index do |details, i|
          hash_of_each_call[@parsed_data_address.first[i]] = archive[i]
        end
      @all_data.push(hash_of_each_call)
    end
      
    @all_data.shift

    #FORMATS DATA INTO ARRAY OF LINKS
    @links = []
    
    @all_data.each do |hash_data|
      formatted_link = {}
      @web_link = "http://web.archive.org/web/#{hash_data["timestamp"]}/#{hash_data["original"]}"
      formatted_link["link"] = @web_link
      formatted_link["date"] = hash_data["timestamp"].to_datetime.strftime('%b %d, %Y')
    
      begin
        page = Nokogiri::HTML(open(@web_link))
        if page.css('h1')[0].nil? || page.css('h1')[0].text == "Internet Archive's Wayback Machine"
          formatted_link["h1"] = "N/A"    
        else
          formatted_link["h1"] = page.css('h1')[0].text
        end
        unless page.css('h2')[0].nil?
          formatted_link["h2"] = page.css('h2')[0].text    
        else
          formatted_link["h2"] = ""
        end
        
      rescue OpenURI::HTTPError => ex
        formatted_link["h1"] = "Timed out. Going on the next one."

      end 
      @links.push(formatted_link)
    end

  end

end
