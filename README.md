# Woosmap Geofencing SDK Example for iOS

The Woosmap Geofencing SDK is a mobile software development kit focused on gathering efficiently the users’ location, triggering events based on region monitoring, and providing categorized users’ zones of interest from geographical and temporal clusters.

The SDK simplifies the integration of the location context in your mobile application by taking care of lower-level functionalities such as data collection or battery management.

## Documentation

All feature descriptions and guides to implement the Woosmap Geofencing Android SDK are available on the [Woosmap developers documentation](https://developers.woosmap.com/products/geofencing-sdk/get-started/).

## Getting Started

### Setup Your Account

When you [sign up](https://www.woosmap.com/en/sign_up?utm_campaign=Woosmap+Sign-up&utm_source=Developers-documentation) for a Woosmap account, you’ll enter your login/password and an email address, and we’ll send you an activation email.

In the activation email, click on the link to activate your account. Once you activate the account login to [Woosmap Console](https://console.woosmap.com/) and follow the steps below.

* [Create An Organization](https://developers.woosmap.com/get-started/#create-an-organization)
* [Create A Project And API Keys](https://developers.woosmap.com/get-started/#create-a-project-and-api-keys)
* [Register a Woosmap Private API key](https://developers.woosmap.com/support/api-keys/#registering-a-woosmap-private-api-key)

## Example

### Load assets in the Woosmap platform and enable Store Search API

In this repository, a sample code is provided for testing quickly the Geofencing Android SDK. Once this code built, a sample app allows you to monitor Point of Interest (previously loaded in the Woosmap Platform). Before runing the example, each POI has to be created as an asset in the Woosmap Console and the Store Search API must be enabled:

**Create an asset for each POI you want to monitor with a geofence**
<img width="800" alt="image" src="https://github.com/Woosmap/geofencing-example-android/assets/79836861/8bd43617-e6f4-4fbb-adc3-6bb547c59d6e">

**Enable Woosmap Store Search API**
<img width="800" alt="image" src="https://github.com/Woosmap/geofencing-example-android/assets/79836861/6070df46-4e44-44ff-821f-cba28634bc49">

### Run the sample app

To run the example, first clone this repository and replace the private key in `AppDelegate.swift` with your own private key. Make sure you have secured your private key.

The sample application has following components. 

* List of locations obtained from `LocationServiceDelegate` .

* List of events obtained using `RegionsServiceDelegate`.

<img src="/wiki/landingscreen.png"  width="300">

<img src="/wiki/location.png"  width="300">

<img src="/wiki/region.png"  width="300">
