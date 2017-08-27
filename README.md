> WORK IN PROGRESS - DO NOT USE

- Add pagination to transactions flow
- Add an attachments flow to transactions
- Add all the authentication flow
- Add tests to all calls
- Look into a working CI solution (Buddybuild doesn't seem to like Linux builds)
- Tidy up GitHub versions, make the working version 1
- Add security to all endpoints to ensure values meet criteria (e.g. feed item must have a non empty title)
    - Maybe use Vapor's "Validation" feature? dunno
- Documentation sweep

# Monzo Client for Vapor

[![Swift](https://img.shields.io/badge/Swift-3.1-orange.svg?style=flat)](https://swift.org) [![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=59a0096f544c6c000177522a&branch=master&build=latest)](https://dashboard.buddybuild.com/apps/59a0096f544c6c000177522a/build/latest?branch=master)

A Monzo client that provides an interface to the public Monzo API. It's built around [Vapor](https://vapor.codes/), and designed for usage in server-side Swift environments.

Inspiration was taken from [monzo-swift](https://github.com/marius-serban/monzo-swift), and for a UIKit solution take a look at [MondoKit](https://github.com/pollarm/MondoKit).

Whilst I've made as much effort to make errors as informative as possible, I recommend checking out the [Monzo Docs](https://monzo.com/docs/#introduction)

Also I highly recommend joining the [Monzo Developers Slack group](https://devslack.monzo.com). I couldn't have done this project without the great community on there!

### Requirements

This framework is designed to work against Swift 3.1, and Vapor 2.0

### Installation

Installation is done using Swift Package Manager, open your `Package.swift` file and add a new dependency!

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Sherlouk/monzo-vapor.git", majorVersion: 1),
    ]
)
```

## Getting Started

### Initialise a client

A `MonzoClient` acts as a way to bind all users, authorisation and API requests to a provided client.

Before you begin, you will need to create a client in the [Monzo Development Tools](https://developers.getmondo.co.uk/)!

```swift
let client = MonzoClient(publicKey: "...", privateKey: "...", httpClient: Droplet.client)
```

> A `MonzoClient` will require a reference to the client object within your [Vapor Droplet](https://docs.vapor.codes/2.0/vapor/droplet/) for networking requests.

### Authenticate a user

> Incomplete

### Load Accounts

Most of the functionality within Monzo is bound to a particular account, obtaining accounts for a user is easy!

```swift
let accounts = try user.accounts()
```

> Using undocumented functionality you can also retrieve current accounts, see the [undocumented section](https://github.com/Sherlouk/monzo-vapor#undocumented)

### Fetch Balance

```swift
let balance = try account.balance()

let spentToday = try account.spentToday()
```

### Fetch Transactions

```swift
let transactions = try account.transactions()
```

### Send Feed Item

The Monzo app is based around a reverse-chronological feed containing various items.

This method allows you to insert your own items into that feed.

Feed items must be of high value to the user, and while the appearance is customisable - care should be taken to ensure it matches the aesthetic of the Monzo mobile apps.

```swift
let feedItem = BasicFeedItem(title: "...", imageUrl: "...")

// There are also some optional parameters for further customisation
let feedItem = BasicFeedItem(..., openUrl: "...",
                                  body: "...",
                                  options: [
                                    .backgroundColor("#ABCDEF"),
                                    .titleColor("#ABCDEF"),
                                    .bodyColor("#ABCDEF")
                                  ])

try account.sendFeedItem(feedItem)
```

### Webhooks

> Incomplete

### Attachments

> Incomplete

### Error Handling

> Incomplete

### Ping

Taking authentication aside this simple ping test allows you to check that you are able to reach the Monzo API.

If the response is `false` then I suggest you wait a bit before trying to run further requests!

```swift
let success = monzoClient.ping()
```

### Undocumented

The Monzo API is currently in it's own mode of beta, and is not designed for public use. There is a ticket on the [public roadmap](https://trello.com/b/9tcaMB4w/monzo-transparent-product-roadmap) currently under "Long Term" which is for the new public API and features such as Sandbox Payments.

Given that, it's fair and understandable that not every endpoint is documented. With that understanding I wanted to enable this framework to have access to all the endpoints I discover but with a clear warning that these are undocumented and might change.

```swift
// Retrieve Current Accounts instead of Prepaid Accounts
// If you'd like both types, then you'll need to make two requests
let accounts = try user.accounts(fetchCurrentAccounts: true)

// TODO:
// /feed?account_id=$account_id

```

## Support

I plan on keeping this framework up-to-date as the public Monzo API evolves. If you have any issues, or questions about this then please raise a [GitHub Issue](https://github.com/Sherlouk/monzo-vapor/issues/new).

When raising issues please try and include as much relevant information as possible including any reproduction steps!

## License

I'm releasing this framework under the [MIT License](https://github.com/Sherlouk/monzo-vapor/blob/master/LICENSE.md).
