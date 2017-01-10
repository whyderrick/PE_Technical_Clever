# Supporting Clever's Instant Login

Clever makes it simple for people working and learning in schools to use the apps they love. If you're a developer, we make it easier for you to become an app they love by adding you to our application portal and removing the friction they find in the log in process. In this guide, we'll build Math Turtle, a web app using the Sinatra framework for Ruby that implements Clever's **Instant Login**. Instant Login uses the OAuth 2.0 standard, so if you're familiar with that, you'll be off and running quickly. (If you're not, [GitHub's OAuth primer](https://developer.github.com/v3/oauth/)) is a great place to learn what you'll need to know).

By the time you've gone through this guide, you'll see how Clever issues an access code, exchanges a token, and identifies users at the `/me` endpoint. If you're looking to log in to Clever from a native mobile app, take a look at [Instant Login for Mobile](https://dev.clever.com/instant-login/mobile). If you're running a Flash-based app, consider using our guide for [Implicit Grant Authorization](https://dev.clever.com/instant-login/mobile). Once you're ready, you can check Math Turtle's [source code](https://github.com/whyderrick/PE_Technical_Clever) and the [deployed app](https://powerful-bastion-48733.herokuapp.com/).

## Common Gotchas & Key Links
In our ideal world, software announces its dependencies and quirks upfront. That isn't the world of production code, but it is the world of this blog post. Before we dive into building Math Turtle, we're going to call out a few common hangups. If you want to get straight to implementing with the guide, skip ahead and remember to check here first if you find yourself confused.

- **Redirect URLS**
  - These are where users will land after they're authenticated. Other services sometimes also call them **Callback URLs** instead.
  - Preregister Redirect URLs for your application through your [application dashboard](https://apps.clever.com/applications). Our OAuth implementation is a strict one that requires it.
  - Your first registered Redirect URL has to be publicly accessible on the web. We ping it as part of authentication, so having localhost in this position (even if it's where you're redirecting to start) will cause errors.
- **District Setup and Login**
  - All Clever-generated sandboxes have the same seed data. You should  [download a csv here](https://dev.clever.com/archives/sandbox/cleverusd.zip). Use any `<role>_id` as both the username and password to log in as that user.
  - Generate a working **Log in with Clever** button at [this link](https://dev.clever.com/instant-login/log-in-with-clever#try-it-out-)
  - You can specify the district you're logging into via your redirect uri param for endpoints that accept a `district_id`. This allows you bypass [setting up sandbox district](https://dev.clever.com/guides/creating-district-sandboxes) that appears in our district picker while you're ramping up.
  - Our recommended process for logouts is [listed here](https://dev.clever.com/instant-login/users#handling-logout). If someone logs out of your app, don't log them out of Clever entirely – they might just be switching to another tool!
- **OAuth Sample code**
  - For [Python](https://github.com/Clever/clever-oauth-examples/tree/master/python)
  - For [PHP](https://github.com/Clever/clever-oauth-examples/tree/master/php)
  - For Ruby applications via an [OmniAuth gem](https://github.com/Clever/omniauth-clever)

Now that we've pointed out the pitfalls, let's start building!

## Getting an Authorization Code & Access Token
Logging into Math Turtle through Clever starts with a link. This link is the bridge between Clever's login and our app. When a user clicks it, they're routed to Clever to log in. Once they've provided valid credentials, they'll land on back the Math Turtle site with a one-time access code that we can send to Clever to receive a long-term authorization token.

### The Authorization Code

We've implemented the **Log in with Clever** button on our home page using the [generator](https://dev.clever.com/instant-login/log-in-with-clever#try-it-out), but creating our own link would be straightforward. Let's examine the link we use in our app: ```https://clever.com/oauth/authorize?response_type=code&client_id=xxxxxxxx&redirect_uri=https://powerful-bastion-48733/clever_login&district_id=586ab58e66da360001c74b06```.  

Our link to `https://clever.com/oauth/authorize` passes three required values in its query string. First, we have `response_type=code`. This tells Clever's server that you want an access code, and `code` is the only accepted value for this endpoint. Next, we have `client_id=<Math_Turtle_client_id>` which identifies Math Turtle (and later your app) as the one that wants to log this user in. Lastly, we have our `redirect_uri`. This tells Clever where to send the user and their access code after they've successfully logged in. Any value that isn't preregistered in Math Turtle's [application dashboard](https://apps.clever.com/applications) will return an `invalid_uri error` response, so be sure to check your path matching if you run into that error message.

 Our `redirect_uri` value has an optional component to it. We've passed a `district_id` which Clever checks and automatically assigns as the district for anyone signing in through this link. For Math Turtle, specifying the district works wonderfully. We already generate a custom app page for each district and this reduces sign in friction for users. For other apps, it might be better practice to let the user choose their district when they sign in to Clever.

Here's a link to a YouTube video showing the flow for Math Turtle:

[![Clever's Login Screen](../img/clever_login.png =500x280)](https://youtu.be/zTXWJvK0M00)

### The Access Token
Now that we're back inside the Math Turtle app, we want to hand our authorization code back to Clever in for an access token. We do this by sending a `POST` request to `https://clever.com/oauth/tokens`. We'll need to authenticate this request with [HTTP Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication). Our `client_id` is our username and our `client_secret` is our password. (You can look those up for your own projects [here](https://apps.clever.com/applications)).

The body of your `POST` request needs to the following three parameters:

- `code`, with its value set to the authorization code Math Turtle received in the url when the user returned from Clever's login portal.
- `grant_type`, with its value set to "authorization_code".
- `redirect_uri`, with its value set to the same place you the login routed the user to (in this case, our current page)

Math Turtle built its request using HTTParty. These params are all assigned in the `post_options` variable that's passed to HTTParty in the request. If all of the request parameters are valid, Clever's server will respond with JSON object containing an `access_token`. We need to take hold of that token to use with future requests on behalf of this user. Math Turtle simply writes the the token to the session cookie, but there are other approaches.

## Retrieving Data
Now that we have a token we can retrieve data for our user.
There's no magic to retrieving data from the `/me` endpoint. It's a typical `GET` request to the the Clever API that includes an Authorization header with `Bearer + <token>` as its value.  In the Magic Turtle source code, this is captured in the private `#get_user_details` method.

Clever recommends asynchronous retrieval, and they do so for good reason. The response from Clever's API is a bit slower than the page rendering speed for Magic Turtle. Without an asynchronous approach we had to refresh the page just to see the data we'd requested. Magic Turtle actually sees two requests when a page hits its `/clever_login` route. The first hit swaps an access code for a token (if there is one). Once the page loads, we run a Javascript function called `showProfile`.
  ```
  function showProfile(){
    if($('.profile-container').length > 0) {
      $.ajax({
        url: '/clever_login',
        method: 'get',
      })
      .done(function(msg){
        $('.profile-container').empty();
        $('.profile-container').append(msg);
      })
    }
  }
  ```
 The showProfile function sends a second request to the server. If server-side logic finds a valid token and receives a request for `/clever_login` by AJAX, it'll call `#get_user_details` and replace the contents of the that page.

Here's a link to the process from login to `/me` response:

[![Login to /me](../img/me_result.png =500x215)](https://youtu.be/THw-HIir20U)

## Improving Your Own App
That's it for Math Turtle! We've built a working app that uses Clever Instant Login for authentication. There's plenty more to do from here. The data from the `/me` endpoint is the gateway to the rest of Clever's API. The `id`s present in that response allow you to make fulfillable requests of the APIs other endpoints.
 If your team has or is considering a native mobile app, look into [Instant Login for Mobile](https://dev.clever.com/instant-login/mobile). If you're angling for better security, we know you're after our hearts. We'd also recommend making your server [more resilient against expired tokens](https://developer.github.com/guides/basics-of-authentication/#implementing-persistent-authentication).
Whatever is next for you and your team, our team at Clever is here to help you accomplish it. If you need a hand, take a look at our [help center](https://support.clever.com/hc/en-us). Something in this blog unclear? Leave us a comment and we'll iron it out.
Go forth! Let us know what cool new lesson you learn! 
