# DEV iOS

This is the repo for the [dev.to](/) iOS app. So far it is basically just a weekend project, but if any iOS devs want to jump in and help make this awesome, you are super welcome. We don't have the iOS skills to take this all the way, but maybe you can help!

We are bought in to the Basecamp idea of building for iOS, described in a few articles and talks from them:

https://m.signalvnoise.com/basecamp-3-for-ios-hybrid-architecture-afc071589c25

https://signalvnoise.com/posts/3743-hybrid-sweet-spot-native-navigation-web-content

https://signalvnoise.com/posts/3766-hybrid-how-we-took-basecamp-multi-platform-with-a-tiny-team

https://www.youtube.com/watch?v=SWEts0rlezA

Our app doesn't have the exact same needs that they do, **_and we don't use Turbolinks in our web app_**, so we can't just copy their approach full-on, but I still think this jives for now. To be clear: I'm not sure whether we use Turbolinks native or not, but the part I do agree with is using web views and native nav etc. where possible to start, and thene evolving as is natural.

By leveraging `wkwebviews` as much as possible, I think we can make this all pretty awesome and sync up with our web dev work pretty smoothly. And where it makes sense, we can re-implement certain things fully native, or build entirely native features. Life's a journey, not a destination.

# Thanks for your help!!!
