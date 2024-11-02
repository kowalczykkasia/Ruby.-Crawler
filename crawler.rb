require 'nokogiri'
require 'open-uri'
require 'sequel'

oferts = '/oferty'
base_url = 'https://www.olx.pl'
keyword = 'laptopy'

DB = Sequel.sqlite('products.db')

DB.create_table? :products do
  primary_key :id
  String :title
  String :price
  String :url
  String :details
end

class Product < Sequel::Model
end



def fetch_url(url)
  options = {
  "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36"
}
  begin
    Nokogiri::HTML(URI.open(url, options))
  rescue OpenURI::HTTPError, SocketError => e
    nil
  end
end


def extract_product_data(doc, base_url)
  begin
    products = []
    print "Loading..."
    doc.css('[data-testid="l-card"]').each do |item|
      title = item.css('h6')&.text&.strip
      price = item.at_css('.css-13afqrm')&.text&.strip
      url = "#{base_url}#{item.at_css('.css-z3gu2d')['href']}"
      print "."
      detailsDoc = fetch_url(url)
      if detailsDoc
        details = open_details_url(detailsDoc)
        products << { title: title, price: price, details: details, url: url} if title && price && details && url
      end 
    end
    products
    rescue NoMethodError => e
      puts "#{e.message}"
    end
end

def open_details_url(doc)
  tags = doc.css('.css-rn93um').map do |item|
    item.css('.css-b5m1rv').each do |detail|
      detail.text.strip
    end
  end
  tags.join(', ')
end

def build_search_url(base_url, keywords) 
  query = keywords.split(' ').join('+')
  "#{base_url}q-#{query}"
end

def getSavedData()
  products = Product.all

  products.each do |product|
    puts "Title: #{product[:title]}, Price: #{product[:price]}, Url: #{product[:url]}, Details: #{product[:details]}"
    puts "-----------------------------"
  end
end

def fetchAndSaveData(oferts, base_url, keyword)
  base_url_oferts = "#{base_url}#{oferts}"
  url = build_search_url(base_url_oferts, keyword)
  doc = fetch_url(url)

  products = extract_product_data(doc, base_url)

  products.each do |product|
    Product.create(product)
  end
end


fetchAndSaveData(oferts, base_url, keyword)

getSavedData()