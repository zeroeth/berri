A Berri small jabber bot
========================

Berri is my little bot to test out jabber in ruby. It uses the `blather` gem which is built on top of `xmpp4r`. Blather makes it really easy to use jabber but has some oddities around group chat related events triggering.

Repo is heroku friendly. Rename the .env template to .env and edit the values for local testing. Don't forget to ps:scale app=1 or you will pull out all your hair wondering why its not running.
