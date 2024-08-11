require 'async'
require 'httparty'
require 'nokogiri'

class Property
  # Automatically create getter and setter methods for all attributes
  attr_accessor :id, :pictures, :price, :room, :living_space, :projectile,
                :availability, :address, :further_price_information, :features,
                :descriptions, :energy_and_building_condition, :provider

  # Constructor to initialize the object with the provided attributes
  def initialize(id, pictures, price, room, living_space, projectile,
                 availability, address, further_price_information, features,
                 descriptions, energy_and_building_condition, provider)
    @id = id
    @pictures = pictures
    @price = price
    @room = room
    @living_space = living_space
    @projectile = projectile
    @availability = availability
    @address = address
    @further_price_information = further_price_information
    @features = features
    @descriptions = descriptions
    @energy_and_building_condition = energy_and_building_condition
    @provider = provider
  end

  def display_details
    puts "ID: #{@id}"
    puts "Pictures: #{@pictures}"
    puts "Price: #{@price}"
    puts "Room: #{@room}"
    puts "Living Space: #{@living_space}"
    puts "Projectile: #{@projectile}"
    puts "Availability: #{@availability}"
    puts "Address: #{@address}"
    puts "Further Price Information: #{@further_price_information}"
    puts "Features: #{@features}"
    puts "Descriptions: #{@descriptions}"
    puts "Energy and Building Condition: #{@energy_and_building_condition}"
    puts "Provider: #{@provider}"
  end
end

def main(city='landkreis-muenchen')
  Async do |task|  
    url = "https://www.immowelt.de/suche/#{city}/immobilien"
    dom = get_dom(url)

    links = dom.xpath('//div[contains(@class, "SearchList")]/div/a[@href]').map { |link| link['href'] }
    links.each do |link|
      task.async do
        data = fetch(link)
        property = Property.new(*data)
        property.display_details
      end
    end
  end
end

def fetch(link)
  dom = get_dom(link)

  id = link.match(/.{7}$/).to_s
  pictures = dom.xpath('//div[@data-testid="aviv.CDP.Gallery.DesktopPreview"]//source').map { |picture| picture['srcset'] }
  price = dom.xpath('//span[@data-testid="aviv.CDP.Sections.Hardfacts.Price.Value"]').text
  room = dom.xpath('//span[text()="Zimmer"]/preceding-sibling::span').text
  living_space = dom.xpath('//span[text()="Wohnfläche"]/preceding-sibling::span').text
  projectile = dom.xpath('//span[text()="Geschoss"]/preceding-sibling::span').text
  availability = dom.xpath('//span[text()="Verfügbarkeit"]/preceding-sibling::span').text
  address = dom.xpath('normalize-space(//svg[@data-testid="aviv.CDP.Sections.Location.Address.Icon"]/following-sibling::span)')
  further_price_information = dom.xpath('//div[@data-testid="aviv.CDP.Sections.Price.NotePrice"]/following-sibling::div[1]').text
  features = dom.xpath('//ul[@data-testid="aviv.CDP.Sections.Features.Preview"]//div[@data-testid="aviv.CDP.Sections.Features.Feature"]/span').map { |feature| feature.text }

  main_description_title = dom.xpath('//h2[@data-testid="aviv.CDP.Sections.Description.MainDescription.Title"]').text
  main_description = dom.xpath('normalize-space(//div[@data-testid="aviv.CDP.Sections.Description.MainDescription.GradientTextBox-content"])')
  location_description = dom.xpath('normalize-space(//div[@data-testid="aviv.CDP.Sections.Description.LocationDescription.GradientTextBox-content"])')
  additional_description = dom.xpath('//div[@data-testid="aviv.CDP.Sections.Description.AdditionalDescription.GradientTextBox-content"]/p').text

  descriptions = {
    'main_description_title' => main_description_title,
    'main_description' => main_description,
    'location_description' => location_description,
    'additional_description' => additional_description
  }

  energy_and_building_condition = {}
  energy_features = dom.xpath('//ul[@data-testid="aviv.CDP.Sections.Energy.Features"]/li/div')
  energy_features.each do |feature|
    energy_and_building_condition[feature.xpath('./span[1]').text] = feature.xpath('./span[2]').text
  end

  provider = {}

  intermediary_profile = dom.xpath('//div[@data-testid="aviv.CDP.Contacting.ProviderSection.IntermediaryCard.Logo"]/a[@href]').first['href']
  years_of_partnership = dom.xpath('//div[@data-testid="aviv.CDP.Contacting.ProviderSection"]//div[contains(text(), "Partnerschaft")]').text
  title = dom.xpath('//div[@data-testid="aviv.CDP.Contacting.ProviderSection"]//span[@data-testid="aviv.CDP.Contacting.ProviderSection.ContactCard.Title"]').text

  if !intermediary_profile.empty?
    provider['intermediary_profile'] = intermediary_profile
  end
  if !years_of_partnership.empty? && years_of_partnership.strip =~ /^\d+/
    provider['years_of_partnership'] = years_of_partnership.match(/^\d+/).to_s
  end
  if !title.empty?
    provider['title'] = title
  end

  return [id, pictures, price, room, living_space, projectile, 
  availability, address, further_price_information, features, 
  descriptions, energy_and_building_condition, provider]
end

def get_dom(url)
  response = HTTParty.get(url)
  dom = Nokogiri::HTML(response.body)
  return dom
end

if __FILE__ == $0
  main()
end
