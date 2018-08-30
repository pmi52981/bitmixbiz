# Bitmixbiz

It's non official gem implements work with BitMix.biz API.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'bitmixbiz'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bitmixbiz

## Usage

Gem provides 2 instances:
- `Bitmixbiz::Mixer` - work with API
- `Bitmixbiz::Order` - order configuration

Example of usage: 

``` ruby
key = 'some_secret_key' # Unique identifier
code = 'blahblah' # This code makes sure that you will never receive any of the previous coins you have added to our reserves in any subsequent transactions you make with Bitmix

mixer = Bitmixbiz::Mixer.new key, testnet: true do |agent|
  agent.logger = Logger.new STDOUT
end


order1 = Bitmixbiz::Order.new do |a|
  a.options.code = code
  a.options.shop_id = 1 # ID of your service.
  a.options.address = ['2N9DULHFyYywZBxaHPhiUWpts4Ys2TvmRYr', '2N7MQzc6UQAwNxM6eyHZhnUN1CAVpY44n57']
end # => <Bitmixbiz::Order:0x000000000197d550 @id=nil, @input_address=nil, @host="bitmix.biz", @data={}, @options=#<OpenStruct tax=0.4, delay=24, address=["2N9DULHFyYywZBxaHPhiUWpts4Ys2TvmRYr", "2N7MQzc6UQAwNxM6eyHZhnUN1CAVpY44n57"], randomize=0, code="blahblah", shop_id=1>>

order2 = Bitmixbiz::Order.new do |a|
  a.options.code = code
  a.options.shop_id = 1 # ID of your service.
  a.options.address = ['2NAGuX2bwVp6cki6N231sKaa3zQC6mL7gEb']
end # => <Bitmixbiz::Order:0x0000000001f21f60 @id=nil, @input_address=nil, @host="bitmix.biz", @data={}, @options=#<OpenStruct tax=0.4, delay=24, address=["2NAGuX2bwVp6cki6N231sKaa3zQC6mL7gEb"], randomize=0, code="blahblah", shop_id=1>>
   
   
mixer.create_order! order1


mixer.create_order! order2

p order1
p order2
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/pmi52981/bitmixbiz/issues

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## TODO
- tests