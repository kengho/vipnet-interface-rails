# ViPNet™ Interface

## Summary

ViPNet™ Interface is a web app which collects and shows various information about your ViPNet™ networks' nodes.

![ViPNet™ Interface main window](/doc/img/main.png?raw=true)

## Demo

[Demo](https://vipnet-interface-demo.herokuapp.com) (may load for some time at first run).

Credentials: `demo@example.com:Password`

By now the demo is static and uses data generated using [Faker](https://github.com/stympy/faker) gem (see [lib/tasks/sample_data.rake](sample_data.rake)).

## Features

* accepts `NODENAME.DOC` from NCC and `iplir.conf` from ViPNet™ Coordinator HW via API and stores data in special `HashDiff` model, creating bunch of displayable records
* accepts tickets with ViPNet™ nodes IDs via API and shows them beside
* allows to trace changes in nodes' properties over time
* single-page interface lets you to select any rows on any pages and export data in various formats
* provides powerful search
* allows to check nodes' availability
* shows nodes' statuses (like disabled or deleted)
* main settings customises via admin panel
* auto update page when sonething changes
* and more

## Powered by

* rails and bunch of third-party gems

* [checker](https://github.com/kengho/checker) (rails)

Provides API for checking nodes' availability.

* [vipnet_interface_config](https://github.com/kengho/vipnet_interface_config) (ruby)

Gets `iplir.conf`, tickets and sends it here via API.

* [vipnet_parser](https://github.com/kengho/vipnet_parser) (gem)

Parses incoming files.

* [(to be committed)](https://github.com/kengho/) (windows scripts)

Runs on NCC and sends `NODENAME.DOC` here via API.

## Installing

### Production

For ruby on rails apps I prefer [this way using rvm + passenger + nginx](https://www.phusionpassenger.com/library/walkthroughs/deploy/ruby/ownserver/nginx/oss/install_language_runtime.html/).

* install and setup this app

After that you can collect `POST_ADMINISTRATOR_TOKEN`, `POST_HW_TOKEN`, `POST_TICKETS_TOKEN` and `CHECKER_TOKEN` from `.env`.

* install [vipnet_checker-rails](https://github.com/kengho/vipnet_checker-rails) wherever nodes' accessips available

Write down it's URL (aka `CHECKER_URL`). Put the same `CHECKER_TOKEN` to `.env` as one above.

* install and setup [vipnet_interface_config](https://github.com/kengho/vipnet_interface_config) wherever ViPNet™ Coordinators HW ssh available.

Setup `getter.yml` and `tickets.yml` using tokens above.

* setup this app's "Check availability API"

 Go to `/settings` and change `localhost:8080` to actual `CHECKER_URL` (don't touch `{ip}` and `{token}`).

* setup [(to be committed)](https://github.com/kengho/) on each ViPNet™ Administrator's you want to gather data from

* allow `CHECKER_URL` to make requests over TCP\5100 to accessips

like
```
[tunnel]
...
rule= proto tcp from 192.168.0.10 to anyip:5100 pass
```

You may install this app, [vipnet_interface_config](https://github.com/kengho/vipnet_interface_config) and [checker](https://github.com/kengho/vipnet_checker) on separate servers and setup checker's routes for accessips via Coordinator, but the easiest way is to put one server behind Coordinator and setup all modules there.

### Development

[Instructions](https://gist.github.com/kengho/37f3591a525454567b454d165dbc0132).

## TODO (random order)

* ViPNet™ 4 support
* collecting users' ID's along with nodes' IDs
* custom sort
* advanced datetime search
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
