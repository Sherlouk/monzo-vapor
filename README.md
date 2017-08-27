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

If the user hasn't authorised your client, then you will need to redirect them to Monzo first.

```swift
let client = MonzoClient(publicKey: "...", privateKey: "...", httpClient: Droplet.client)
let uri = client.authorizationURI(redirectUrl: "...", nonce: "...")
// Redirect user to URI
```

> While a nonce is not required, we highly recommend providing a secure and random string to prevent [CSRF attacks](https://www.owasp.org/index.php/Cross-Site_Request_Forgery_%28CSRF%29)!

Once the user authorises your client, they will be redirected to the provided URL.
You will need to setup a route for this URL, and exchange the token - I provide a helpful function for this!

```swift
// Replace this to match the redirectURL
builder.get("oauth/callback") { req in
  // Forward the request, which will in turn validate and exchange the token
  let user = try client.authenticateUser(req, nonce: "...")
}
```

> When authenticating a user, you need to ensure the nonce matches the one used in the previous step.

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
let feedItem = BasicFeedItem(title: "...",
                            imageUrl: "...",
                            openUrl: "...",
                            body: "...",
                            options: [
                              .backgroundColor("#ABCDEF"),
                              .titleColor("#ABCDEF"),
                              .bodyColor("#ABCDEF")
                            ])

try account.sendFeedItem(feedItem)
```

### Webhooks

Webhooks can be used to receive real-time, push notifications of events in an account.

Currently they are only used for new transactions, see [the docs here](https://monzo.com/docs/#transaction-created)!

```swift
// If you haven't previously loaded webhooks, this will fetch them and then return them
try account.webhooks

// Register Webhook
try account.addWebhook(url: "...")

// Remove Webhook
try webhook.remove()
```

### Attachments

> Attachments are currently not supported

### Error Handling

All network requests are designed to throw detailed error messages in the event of something going wrong.

All errors conform to [Debuggable](https://docs.vapor.codes/2.0/debugging/overview/) allowing you to easily debug what's gone wrong.

If in doubt, please raise an issue on GitHub!

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
