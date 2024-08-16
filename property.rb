
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
