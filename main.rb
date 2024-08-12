require 'async'
require 'httparty'
require 'logging'
require 'nokogiri'

class Property
  # Automatically create getter and setter methods for all attributes
  attr_accessor :id, :brief, :pictures, :price, :room, :living_space, :property, :projectile,
                :availability, :address, :main_prices, :additional_prices, :further_price_information, :features,
                :descriptions, :energy_and_building_condition, :provider, :ref_number, :city, :url

  # Constructor to initialize the object with the provided attributes
  def initialize(id, brief, pictures, price, room, living_space, property, projectile,
                 availability, address, main_prices, additional_prices, further_price_information, features,
                 descriptions, energy_and_building_condition, provider, ref_number, city, url)
    @id = id
    @brief = brief
    @pictures = pictures
    @price = price
    @room = room
    @living_space = living_space
    @property = property
    @projectile = projectile
    @availability = availability
    @address = address
    @main_prices = main_prices
    @additional_prices = additional_prices
    @further_price_information = further_price_information
    @features = features
    @descriptions = descriptions
    @energy_and_building_condition = energy_and_building_condition
    @provider = provider
    @city = city
    @url = url
    @ref_number = ref_number
  end

  def data
    return {
      'id' => @id,
      'brief' => @brief,
      'pictures' => @pictures,
      'price' => @price,
      'room' => @room,
      'living_space' => @living_space,
      'property' => @property,
      'projectile' => @projectile,
      'availability' => @availability,
      'address' => @address,
      'main_prices' => @main_prices,
      'additional_prices' => @additional_prices,
      'further_price_information' => @further_price_information,
      'features' => @features,
      'descriptions' => @descriptions,
      'energy_and_building_condition' => @energy_and_building_condition,
      'provider' => @provider,
      'city' => @city,
      'url' => @url,
      'ref_number' => @ref_number
    }
  end
end

def main(city='landkreis-muenchen')
  Async do |task|
    $logger.info "Scraping #{city} begins"
    url = "https://www.immowelt.de/suche/#{city}/immobilien"
    dom = get_dom(url)

    links = dom.xpath('//div[contains(@class, "SearchList")]/div/a[@href]').map { |link| link['href'] }
    links.each do |link|
      task.async do
        $logger.info "Fetching #{link}"
        data = fetch(link)
        property = Property.new(*data, city, link)
      end
    end
  end
end

def fetch(link)
  dom = get_dom(link)

  id = link.match(/.{7}$/).to_s
  brief = dom.xpath('normalize-space(//div[@data-testid="aviv.CDP.Sections.Hardfacts"]/div[1])')
  pictures = dom.xpath('//div[@data-testid="aviv.CDP.Gallery.DesktopPreview"]//source').map { |picture| picture['srcset'] }
  price = dom.xpath('//span[@data-testid="aviv.CDP.Sections.Hardfacts.Price.Value"]').text
  room = dom.xpath('//span[text()="Zimmer"]/preceding-sibling::span').text
  living_space = dom.xpath('//span[text()="Wohnfläche"]/preceding-sibling::span').text
  property = dom.xpath('//span[text()="Grundstück"]/preceding-sibling::span').text
  projectile = dom.xpath('//span[text()="Geschoss"]/preceding-sibling::span').text
  availability = dom.xpath('//span[text()="Verfügbarkeit"]/preceding-sibling::span').text
  address = dom.xpath('normalize-space(//svg[@data-testid="aviv.CDP.Sections.Location.Address.Icon"]/following-sibling::span)')

  main_prices = {}
  all_prices = dom.xpath('//div[@data-testid="aviv.CDP.Sections.Price.MainPrice"]/div[not(@data-testid)]')
  all_prices.each do |price|
    if all_prices.find_index(price) == 0
      main_prices[price.xpath('./div[1]/div[1]').text] = price.xpath('./div[2]/span[1]').text
    else
      main_prices[price.xpath('./div/div[1]/div[1]').text] = price.xpath('./div/div[2]/span').text
    end
  end

  commission_fee = dom.xpath('//div[@data-testid="aviv.CDP.Sections.Price.MainPrice.commissionFee"]')
  if !commission_fee.empty?
    main_prices['commission_fee'] = commission_fee.xpath('./div[2]').text
  end

  additional_prices = {}
  all_prices = dom.xpath('//div[@data-testid="aviv.CDP.Sections.Price.AdditionalPrice"]/div')
  all_prices.each do |price|
    additional_prices[price.xpath('normalize-space(./div[1])')] = price.xpath('normalize-space(./div[2])')
  end

  further_price_information = dom.xpath('//div[@data-testid="aviv.CDP.Sections.Price.NotePrice"]/following-sibling::div[1]/text()').map { |text| text.text }
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
  efficiency_class = dom.xpath('//div[@data-testid="aviv.CDP.Sections.Energy.Preview"]/div[@data-testid="aviv.CDP.Sections.Energy.Preview.EfficiencyClass"]')
  if !efficiency_class.empty?
    energy_and_building_condition['efficiency_class'] = efficiency_class.text
  end
  energy_features = dom.xpath('//ul[@data-testid="aviv.CDP.Sections.Energy.Features"]/li/div')
  energy_features.each do |feature|
    energy_and_building_condition[feature.xpath('./span[1]').text] = feature.xpath('./span[2]').text
  end

  intermediary_profile = dom.xpath('//div[@data-testid="aviv.CDP.Contacting.ProviderSection.IntermediaryCard.Logo"]/a[@href]')
  years_of_partnership = dom.xpath('//div[@data-testid="aviv.CDP.Contacting.ProviderSection"]//div[contains(text(), "Partnerschaft")]')
  title = dom.xpath('//div[@data-testid="aviv.CDP.Contacting.ProviderSection"]//span[@data-testid="aviv.CDP.Contacting.ProviderSection.ContactCard.Title"]')

  provider = {
    'intermediary_profile' => !intermediary_profile.empty? ? intermediary_profile.first['href'] : '',
    'years_of_partnership' => years_of_partnership.text.strip =~ /^\d+/ ? years_of_partnership.text.match(/^\d+/).to_s : '',
    'title' => title.text
  }

  ref_number = dom.xpath('//div[@data-testid="aviv.CDP.Sections.ClassifiedKeys.Key.1"]/text()').text.sub!(/^: /, '')

  return [id, brief, pictures, price, room, living_space, property, projectile,
  availability, address, main_prices, additional_prices, further_price_information, features,
  descriptions, energy_and_building_condition, provider, ref_number]
end

def get_dom(url)
  response = HTTParty.get(url)
  dom = Nokogiri::HTML(response.body)
  return dom
end

def ad_exists(url)
  dom = get_dom(url)
  deleted_message = dom.xpath('//div[text()="Anzeige gelöscht"]/following-sibling::div[text()="Diese Anzeige wurde bereits gelöscht, aber es warten viele andere auf dich."]')
  return deleted_message.empty? ? true : false
end

if __FILE__ == $0
  $logger = Logging.logger['scraper_logger']
  $logger.level = :info
  $logger.add_appenders \
    Logging.appenders.stdout,
    Logging.appenders.file('logs.log')

  main()
end
