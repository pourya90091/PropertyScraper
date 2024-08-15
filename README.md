# Property Scraper

## Setup and Use

### Install Requirements

```bash
bundle install
```

### Usage

#### main()
- **city** (String) => Name of a city; Example: landkreis-muenchen.
- **start_page** (Integer) => The page for start-point of Scraper (default=1).
- **end_page** (Integer) => The page for stop-point of Scraper (default=1).
- **fetch_pic** (Boolean) => If set `true`, the Scraper will fetch all available pictures (return as a Hash), otherwise (`false`) only fetches a few pictures (return as an Array).

>Note: There is also a `page` parameter that acts as a counter, so do not give it value.

### Output
The scraped data will be saved as a Property class.

#### Property class attributes
- id (String) => ID of the ad ().
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
