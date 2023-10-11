# Local Keep

A program to quickly capture any fleeting thoughts.

<!-- 翻译申明 -->
(My English is very poor, so I have resorted to machine translation, so please excuse me!)

<!-- 功能简介 -->
- Privacy Priority
- Data is stored locally
- No need to register and log in
- Text, audio, photo, video

<!-- 开发原因 -->
## Reasons for development
I used to use Google Keep to keep track of flashbacks, which was convenient and worked well, but in the last couple of years I've become more privacy-conscious, so I don't want to log into a Google account, and the Apps on Android are mainly installed from F-Droid, with a few that I can't find open-source alternatives to download and install as APKs. Gmail on Linux is only logged into Thunderbird, and doesn't share the same set of cookies as Firefox, which is my main use.

If I don't log in to Google, I can't continue to use Keep. I've searched for a lot of alternatives, but I'm not satisfied with them, and most of the ones that fulfill my needs require me to register and log in, and the data is controlled by the service provider, typically TickTick, but the ones that I can control by myself aren't satisfactory, and it's either cumbersome to operate them, or they support too few types of media, or they don't have a function that accepts sharing on the cell phone.

In the end, I forced myself to learn Flutter to do a hands-on, I want to have the following features:
1. cross-platform, I need to use on Linux and Android. 
2. data localization, I use Syncthing to synchronize between multiple devices.
3. easy to operate, open and input.
4. fast incoming, when I read a book or web page on my phone, I can share text or images directly into it and process them later on my computer.