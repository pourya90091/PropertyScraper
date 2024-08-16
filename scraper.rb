require 'concurrent-ruby'
require 'httparty'
require 'logging'
require 'nokogiri'
require 'ferrum'
require_relative 'property'

def crawl(city: 'landkreis-muenchen', start_page: 1, end_page: 1, fetch_pic: false, timeout: 5, max_retry: 5, page: nil, properties: [])
  set_logger()
  $timeout = timeout
  $max_retry = max_retry
  page = !page ? start_page : page

  $logger.info "Scraping #{city} begins (page #{page})"
  url = "https://www.immowelt.de/suche/#{city}/immobilien/mk?sp=#{page}"
  dom = get_dom(url)

  $links = dom.xpath('//div[contains(@class, "SearchList")]/div/a[not(contains(@href, "projekte"))]').map { |link| link['href'] }
  $logger.info "#{$links.length} ad(s) found (page #{page})"
  promises = $links.map do |link|
    Concurrent::Promise.execute do
      begin
        if ad_exists(link)
          $logger.info "Fetching #{link}"
          data = fetch(link, fetch_pic)
          property = Property.new(*data, city, link)
          properties.push(property)
          $logger.info "Fetched #{link}"
        else
          $logger.info "Not available ad (#{link})"
        end
      rescue Exception => err
        $logger.error "Error (#{link}): #{err}"
      end
    end
  end

  # Wait for all promises to complete
  results = promises.map(&:value)
  if $links.length < 1 || page == end_page
    $logger.info "#{city} Scraped completely"
    return properties
  end
  crawl(city: city, start_page: start_page, end_page: end_page, fetch_pic: fetch_pic, timeout: timeout, max_retry: max_retry, page: page + 1, properties: properties)
end

def fetch(link, fetch_pic)
  dom = get_dom(link)

  id = link.match(/.{7}$/).to_s
  brief = dom.xpath('normalize-space(//div[@data-testid="aviv.CDP.Sections.Hardfacts"]/div[1])')
  if fetch_pic
    # A hashmap that contains all pictures (titles and urls)
    pictures = fetch_pictures(link)
  else
    # An Array that contains few pictures (without titles, only urls)
    pictures = dom.xpath('//div[@data-testid="aviv.CDP.Gallery.DesktopPreview"]//source').map { |picture| picture['srcset'] }
  end
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
    if price['class'] == 'css-1fobf8d'
      additional_prices[price.xpath('./descendant::div[text()][2]').text] = price.xpath('./descendant::span[1]').text
    else
      additional_prices[price.xpath('normalize-space(./div[1])')] = price.xpath('normalize-space(./div[2])')
    end
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

def fetch_pictures(link)
  def load_pictures(browser, all_pictures, retry_counter=1)
    pictures = browser.xpath('//picture[contains(@id, "picture")]')
    if pictures.length < all_pictures
      if retry_counter < $max_retry
        retry_counter += 1
        sleep($timeout)
        load_pictures(browser, all_pictures, retry_counter)
        end
    end
    return pictures
  end

  pictures_hashmap = {}
  duplicate_counter = 2
  retry_counter = 1
  browser = Ferrum::Browser.new(timeout: $timeout)

  begin
    browser.go_to(link + '#masonry-modal')
  rescue
    # Wait and retry
    sleep(0.5)
    if retry_counter < $max_retry
      retry_counter += 1
      retry
    end
  end
  browser.evaluate('document.body.style.zoom = "1%"')

  # Getting number of all available pictures
  all_pictures_xpath = '//div[@data-testid="aviv.CDP.Gallery.MasonryModal.TopBar"]//div[contains(text(), "Bilder")]'
  element_exists = wait_for(all_pictures_xpath, browser)
  if element_exists
    all_pictures = browser.at_xpath(all_pictures_xpath).text.match(/^\d+/).to_s.to_i
  else
    # An exception; When there is less than 4 pictures
    $logger.info "Can't fetch all available pictures (#{link})"
    dom = get_dom(link)
    pictures = dom.xpath('//div[@data-testid="aviv.CDP.Gallery.DesktopPreview"]//source').map { |picture| picture['srcset'] }
    browser.quit
    return pictures
  end

  pictures = load_pictures(browser, all_pictures)
  pictures.each do |picture|
    url = picture.at_xpath('./source[last()]')['srcset']
    title = picture.at_xpath('./img').description['attributes']
    title = title[title.index('aria-label') + 1]
    if pictures_hashmap.key?(title)
      title = "#{title}_#{duplicate_counter}"
      duplicate_counter += 1
    end
    pictures_hashmap[title] = url
  end

  browser.quit

  return pictures_hashmap
end

def get_dom(url)
  response = HTTParty.get(url)
  dom = Nokogiri::HTML(response.body)
  return dom
end

def ad_exists(url)
  dom = get_dom(url)
  price = dom.xpath('//span[@data-testid="aviv.CDP.Sections.Hardfacts.Price.Value"]')
  return price.empty? ? false : true
end

def wait_for(xpath, browser)
  start_time = Time.now
  begin
    if (Time.now - start_time) > $timeout
      return false
    end
    if browser.at_xpath(xpath).nil?
      raise "Error"
    end
  rescue
    sleep(0.1)
    retry
  else
    return true
  end
end

def set_logger()
  $logger = Logging.logger['scraper_logger']
  $logger.level = :info
  $logger.add_appenders \
    Logging.appenders.stdout,
    Logging.appenders.file('logs.log')
end

if __FILE__ == $0
  properties = crawl()
  properties.each do |property|
    puts property.data
  end
end
