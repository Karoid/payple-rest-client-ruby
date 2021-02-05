# Payple

Ruby 사용자를 위한 [페이플](https://www.payple.kr/) REST API 연동 모듈입니다.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'httparty'
gem 'payple', git: 'https://github.com/Karoid/payple-rest-client-ruby'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install payple

### Configuration

```ruby
Payple.configure do |config|
  config.cst_id = 'test'
  config.cust_key = 'abcd1234567890'
  config.refund_key = 'a41ce010ede9fcbfb3be86b24858806596a9db68b79d138b147c3e563e1829a0'
  config.is_test_mode = true
end
```

## Usage

### 인증 URL 생성하기
```ruby
# Controller 액션 생성
def payple_auth
  render json: Payple.auth_raw
end
```

### 간편결제(비밀번호, 일회성), 앱카드결제 가맹점 인증 요청
배열의 첫번째 요소로 다음 결제 url, 두번째 요소로 인증과 관련된 정보가 출력된다.
```ruby
Payple.auth
=> [
  "https://testcpay.payple.kr/index.php?ACT_=PAYM&CPAYVER=202102051731", 
  {
    :PCD_CST_ID=>"N2hQWnYrZFpYc1crYnpiR1dTMzdzQT09", 
    :PCD_CUST_KEY=>"V3lNUzNXNU4wNW1uZlFMejFGdktyQT09", 
    :PCD_AUTH_KEY=>"K0VnWlZ5TWZSaGNla1Vpay96YnNQQTFnYXcyVWxlSzJGTHdtNHpNTndIUmJIZ2IrUFI1VExnZzhvOGNqS2MwR0RXL2ZVVjNXbUNBSG43ajdJNXJlelZuKzBXenZNa2RQSGMwdzJlNndBS3dwMTF4Y29OMkdEaFI4RjZSQVpidVpkNkprbkcwalF0L05xaVFOSXk4WWZqUVg2YUJNSnJiTEFwT05WOXhzSWRaRGFWN1NxeitkTkdWeDFjV2l6dVVRakZ0MVVGWTA0ZW9rZWlvbE0xNmZHRGlyczNrWEtTUkhxakpoWDhqWTFxUUF4N1pseW05QTVFbGY5VUs4WExHRDRubEs4Z3JiOTFNS2djKzZLUDN2RVE9PQ=="
  }
]
```

### 그 외 인증 요청
[페이플 공식 문서](https://docs.payple.kr/card/install/auth)에서 cst_id, custKey를 제외한 파라미터를 함수의 인자로 넘기면 원하는 결과가 출력된다.

다음은 정기결제 가맹점 인증 요청 예시코드이다.

배열의 첫번째 요소로 다음 결제 url, 두번째 요소로 인증과 관련된 정보가 출력된다.
```ruby
Payple.auth({PCD_PAYCHK_FLAG: "Y"})
=> [
  "https://testcpay.payple.kr/php/PayChkAct.php", 
  {
    :PCD_CST_ID=>"N2hQWnYrZFpYc1crYnpiR1dTMzdzQT09", 
    :PCD_CUST_KEY=>"V3lNUzNXNU4wNW1uZlFMejFGdktyQT09", 
    :PCD_AUTH_KEY=>"K0VnWlZ5TWZSaGNla1Vpay96YnNQQTFnYXcyVWxlSzJGTHdtNHpNTndIUmJIZ2IrUFI1VExnZzhvOGNqS2MwR0RXL2ZVVjNXbUNBSG43ajdJNXJlelZuKzBXenZNa2RQSGMwdzJlNndBS3dwMTF4Y29OMkdEaFI4RjZSQVpidVpkNkprbkcwalF0L05xaVFOSXk4WWZqUVg2YUJNSnJiTEFwT05WOXhzSWRaRGFWN1NxeitkTkdWeDFjV2l6dVVRakZ0MVVGWTA0ZW9rZWlvbE0xNmZHRGlyczNrWEtTUkhxakpoWDhqWTFxUUF4N1pseW05QTVFbGY5VUs4WExHRDRubEs4Z3JiOTFNS2djKzZLUDN2RVE9PQ=="
  }
]
```

### 결제 내역 조회
```ruby
Payple.payment(
  pay_type: :transfer,
  oid: 'test201804000001',
  pay_date: '20200320'
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/payple. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/payple/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Payple project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/payple/blob/master/CODE_OF_CONDUCT.md).
