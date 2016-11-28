# ViPNet™ Interface

## Summary

ViPNet™ Interface is a web app which collects and shows various information about your ViPNet™ networks' nodes.

![ViPNet™ Interface main window](/doc/img/main.png?raw=true)

## Demo

[demo will be here](https://www.example.com)

## Features

* accepts `NODENAME.DOC` from NCC and `iplir.conf` from ViPNet™ Coordinator HW via API and stores data in special `HashDiff` model, creating bunch of displayable records
* accepts tickets with ViPNet™ nodes IDs via API and shows them beside
* allows to trace changes in nodes' properties over time
* single-page interface lets you to select any rows on any pages and export data in various formats
* provides powerful search
* allows to check nodes' availability
* shows nodes' statuses (like disabled or deleted)
* main settings customises via admin panel
* and more

## Powered by

* rails and bunch of third-party gems

* [vipnet_checker-rails](https://github.com/kengho/vipnet_checker-rails) (rails)

Places wherever nodes' accessips available and provides API for checking their availability.

* [vipnet_interface_config](https://github.com/kengho/vipnet_interface_config) (ruby)

Gets `iplir.conf`, tickets and sends it here via API.

* [vipnet_parser](https://github.com/kengho/vipnet_parser) (gem)

Parses incoming files.

* [(to be committed)](https://github.com/kengho/) (windows scripts)

Runs on NCC and sends `NODENAME.DOC` here via API.

## Installing

I prefer this way using [rvm + passenger + nginx](https://www.phusionpassenger.com/library/walkthroughs/deploy/ruby/ownserver/nginx/oss/install_language_runtime.html/). Tested on Ubuntu 14.04.

## TODO (random order)

* ViPNet™ 4 support
* collecting users' ID's along with nodes' IDs
* custom sort
* advanced datetime search
* auto-update page
* fully JSONish data exchange
* show proper version for coordinators
* show IP in main page
* user setup columns' visibility
* user invites
* user registration
* MS Windows AD integration

## License

ViPNet™ Interface is distributed under the MIT-LICENSE.

ViPNet™ is registered trademark of InfoTeCS Gmbh, Russia.
