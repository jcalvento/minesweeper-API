# minesweeper-API 

## The Game
Develop the classic game of [Minesweeper](https://en.wikipedia.org/wiki/Minesweeper_(video_game))

## What to build
The following is a list of items (prioritized from most important to least important) we wish to see:
- [x] Design and implement a documented RESTful API for the game (think of a mobile app for your API)
- [x] Implement an API client library for the API designed above. Ideally, in a different language, of your preference, to the one used for the API
- [x] When a cell with no adjacent mines is revealed, all adjacent squares will be revealed (and repeat)
- [x] Ability to 'flag' a cell with a question mark or red flag
- [x] Detect when game is over
- [x] Persistence
- [x] Time tracking
- [x] Ability to start a new game and preserve/resume the old ones
- [x] Ability to select the game parameters: number of rows, columns, and mines
- [ ] Ability to support multiple users/accounts

## Setup
- Used ruby 2.7.2 and rails 6.0.3
- Clone the repo and run `bundle install` to install dependencies
- Run migrations `rake db:migrate` or `RAILS_ENV=test rake db:migrate` to run the on test env
- `rspec` to run tests
- `rails s` to start server

## Notes
- Heroku url: https://frozen-citadel-76869.herokuapp.com
- [API Documentation](./api_doc.yaml)
- [API client](https://github.com/jcalvento/minesweeper-client)
- Board coordinates are (x, y) where x=0 is the top left column and y=0 is the top left row 
```
|(0, 0)|(1, 0)|(2, 0)|...|
|(0, 1)|(1, 1)|(2, 1)|...|
|(0, 2)|(1, 2)|(2, 2)|...|
```
- Used [Rspec](https://rspec.info) for tests, with [shoulda-matchers](https://github.com/thoughtbot/shoulda-matchers) and [timecop](https://github.com/travisjeffery/timecop)
- Left out multiple users/accounts to avoid expending more time but it shouldn't be difficult. For authentication could use [Device](https://github.com/heartcombo/devise) or just and email to identify the user and associate it to the board (if no auth required)