require 'async'
require 'httparty'
require 'nokogiri'

class property
  def initialize()

  end
end

def main(city='landkreis-muenchen')
  Async do |task|  
    url = "https://www.immowelt.de/suche/#{city}/immobilien"
    dom = get_dom(url)

    links = dom.xpath('//div[contains(@class, "SearchList")]/div/a[@href]').map { |link| link['href'] }
    links.each do |link|
      task.async do
        dom = get_dom(link)
        fetch(dom)
      end
    end
  end
end

def fetch(dom)
  id = links[0].scan(/\/(.{7})$/)
  pictures = dom.xpath('//div[@data-testid="aviv.CDP.Gallery.DesktopPreview"]//source').map { |picture| picture['srcset'] }
  price = dom.xpath('//span[@data-testid="aviv.CDP.Sections.Hardfacts.Price.Value"]').text
  room = dom.xpath('//span[text()="Zimmer"]/preceding-sibling::span').text
  living_space = dom.xpath('//span[text()="Wohnfläche"]/preceding-sibling::span').text
  projectile = dom.xpath('//span[text()="Geschoss"]/preceding-sibling::span').text
  availability = dom.xpath('//span[text()="Verfügbarkeit"]/preceding-sibling::span').text
  address = dom.xpath('normalize-space(//svg[@data-testid="aviv.CDP.Sections.Location.Address.Icon"]/following-sibling::span)')
  further_price_information = dom.xpath('//div[@data-testid="aviv.CDP.Sections.Price.NotePrice"]/following-sibling::div[1]/text()')
  features = dom.xpath('//ul[@data-testid="aviv.CDP.Sections.Features.Preview"]//div[@data-testid="aviv.CDP.Sections.Features.Feature"]/span').map { |feature| feature.text }

  main_description_title = dom.xpath('//h2[@data-testid="aviv.CDP.Sections.Description.MainDescription.Title"]').text
  main_description = dom.xpath('normalize-space(//div[@data-testid="aviv.CDP.Sections.Description.MainDescription.GradientTextBox-content"])')
  location_description = dom.xpath('normalize-space(//div[@data-testid="aviv.CDP.Sections.Description.LocationDescription.GradientTextBox-content"])')
  additional_description = dom.xpath('//div[@data-testid="aviv.CDP.Sections.Description.AdditionalDescription.GradientTextBox-content"]/p/text()')

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
end

def get_dom(url)
  response = HTTParty.get(url)
  dom = Nokogiri::HTML(response.body)
  return dom
end

if __FILE__ == $0
  main()
end
