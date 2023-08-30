# Currency Exchange Rate Assessment App

This app is designed to provide users with a quick assessment of the current exchange rate for various foreign currencies relative to the country's currency. It allows users to evaluate the sale and purchase rates of selected foreign currencies and also provides the ability to view historical exchange rates from the national bank for the past year.

## Requirements

- iOS 14 and above
- Internet connectivity for currency rate updates
- Adaptable layout for iPhone and iPad devices in both portrait and landscape orientations
- Ability to work offline
- Update the exchange rate no more than once an hour
- Share exchange rates through messaging apps and more

## Stack

- Swift
- UIKit
- Storyboard for UI design
- Auto Layout for responsive design
- Trait collections for device and orientation adaptation
- URLSession for network requests
- Codable for JSON parsing
- Repository pattern for data management
- Third-party API for currency exchange rate data
- Model-View-Controller (MVC) architectural pattern
- Design tools: Figma for UI/UX design

## Design

For the app's design, we have used elements from the "Text fields" task, and you can find the design at the following Figma link: [Currency Converter Design]

## Additional Features

- The app fetches exchange rates from a public API, for example, [PrivatBank Exchange Rate API](https://api.privatbank.ua/#p24/exchange).
- The app updates exchange rates intelligently, ensuring that it only requests updates once per hour.
- In case an update fails, the app displays the time of the last successful update.

## Installation and Usage

1. Clone this repository to your local machine.

2. Open the Xcode project file.

3. Configure your Xcode environment and build settings.

4. Run the app on the iOS Simulator or a physical device.

5. Connect to the internet to fetch the latest exchange rates.

## Usage Instructions

- Launch the app and input the foreign currency you want to assess for sale and purchase rates.

- View the current exchange rates for the selected currency relative to the country's currency.

- The app updates the exchange rates intelligently, ensuring timely and accurate information.

- Share exchange rates with friends and colleagues using messaging apps.

## Credits

- This app relies on free public APIs for exchange rate data, such as the [PrivatBank Exchange Rate API](https://api.privatbank.ua/#p24/exchange).

- The design of the app was created using Figma, following the "Currency Converter" design template.

- [Hacking with Swift](https://www.hackingwithswift.com/example-code/system/how-to-save-user-settings-using-userdefaults) provided valuable information for managing user settings.

## License

This project is distributed under the [MIT License](LICENSE).

---

For further assistance or inquiries, please refer to the project documentation or contact the project maintainers.
