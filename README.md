# Property Scraper

## Setup and Use

### Install Requirements

```bash
bundle install
```

### Usage

#### crawl()
- **city** (String) => Name of a city; Example: landkreis-muenchen.
- **start_page** (Integer) => The page for start-point of Scraper (default=1).
- **end_page** (Integer) => The page for stop-point of Scraper (default=1).
- **fetch_pic** (Boolean) => If set `true`, the Scraper will fetch all available pictures (return as a Hash), otherwise (`false`) only fetches a few pictures (return as an Array of urls).

### Output
The scraped data will be saved as a Property class.

#### Property class attributes
- id (String) => ID of the ad.
- brief (String) => Type of the property; Example: "WG-Zimmer zur Miete".
- pictures (Array or Hash) => Pictures.
- price (String) => Price; Example: "750 €".
- room (String) => Number of rooms in the property; Example: "4".
- property (String) => Scale (in m²); Example: "17 m²".
- projectile (String) => Projectile; Example: "Ground floor"
- availability (String) => Availability; Example: "16.11.2024"
- address (String) => Address; Example: "Münchener 
Straße 17, Winning, Taufkirchen (82024)"
- main_prices (Hash) => Main prices.
- additional_prices (Hash) => Additional prices.
- further_price_information (Array) => Further price information.
- features (Array) => Features.
- descriptions (Hash) => Descriptions.
- energy_and_building_condition (Hash) => Energy and building condition
details.
- provider (Hash) => Provider.
- city (String) => City.
- url (String) => URL of the ad.
- ref_number (String) => Reference number of the ad.

### Example
```ruby
require_relative 'scraper'

properties = crawl(city: "berlin") # Fetches first page (approximately 20 properties)
properties.each do |property|
  puts property.data
end
```
## Tips

>**Tip** : To obtain `city` value (crawl function parameter), go to https://www.immowelt.de/suche/immobilien and in the "Wo suchst du?" input enter name of a city, zip code or district (like "Berlin"), then select one of the results and push "Jetzt finden" button, then you shuld be at a url like this:
https://www.immowelt.de/suche/berlin/immobilien; select anything between `suche/` and `/immobilien`, which in this case is `berlin`. You now have the `city` value.

>**Tip** : You can get all of Property attributes as a Hashmap using `Property.data()`.

>**Tip** : There are also two other parameters in crawl function (`page`, `properties`) that you don't need give value to them.
---
