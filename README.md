# ViewComponent::Juice

The goal of this gem is to enable writing of interactive view components by levereging the power of turbo, removing the need to write JS.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'view_component-juice'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install view_component-juice

## Usage

Currently a child messaging a parent and a component messaging itself works as expected, but due to the way context is maintained by passing a query parameter a child couldn't message another child. To resolve this, state needs to be stored in a cookie so its more gobally available.

A demonstration component
```rb
class BoardListComponent < ViewComponent::Base
  # Its got the juice!
  include ViewComponent::Juice::Juicy

  # We want to list the user's boards so we need to authenticate them.
  # Juice will try to call a method `current_<name>` like what devise provides
  # and will then make that available with the same method name
  AUTHENTICATE = %i[user]

  # Optional, but when you provide it, it will check that all the messages
  # being sent are one of these
  MESSAGES = %i[open close]

  # This is called when first instanciated in a view and sets up the initial 
  # component state
  def setup(board_ids:)
    @list_open = true

    # For a production application it would be wise to use a scoped id or friendly
    # ID as context is currently not encrypted in the client browser.
    context['board_ids'] = board_ids
  end

  # This is called when the the component is going to be rendered again
  def update(message)
    # As setup is only called when its first rendered in the client,
    # if we didn't set @list_open here, it would be undefined as juice recreates
    # the component instance.
    @list_open = message == :open
  end

  def boards
    @boards ||= current_user.boards.where(context['board_ids'])
  end
end
```

```haml
- # frame is provided by the concern and makes the <turbo-frame> tag with a unique ID
= frame do
  - if @list_open
    .board-list
      - # send_message generates a link to the juice controller which will do an update
      - # cycle
      = link_to 'Close', send_message(:close)
      %p Boards:

      - boards.each do |board|
        = link_to board.name, board

      %hr
      = link_to 'Create new Board', new_board_path
  - else
    = link_to 'Open', send_message(:open), class: 'board-list__closed-button'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/calebowens/view_component-juice.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
