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

<!-- Or install it yourself as:

    $ gem install payple -->

## 국내 결제

### Configuration

```ruby
Payple.cpay.configure do |config|
  config.cst_id = 'test'
  config.cust_key = 'abcd1234567890'
  config.refund_key = 'a41ce010ede9fcbfb3be86b24858806596a9db68b79d138b147c3e563e1829a0'
  config.referer = 'http://localhost:3000'
  config.is_test_mode = true
end
```
만약 테스트 상태라면 is_test_mode 값을 true로 설정한다.
referer에 서비스 URL을 넣어야 한다

### 인증 URL 생성하기
Rails 기준
```ruby
# Controller 액션 생성
def payple_auth
  render json: Payple.cpay.auth_raw
end
```

### CERT 승인하기
일반 결제 일 경우
```ruby
Payple.cpay.cert_confirm(cert_url: "반환받은 PCD_PAY_COFURL", auth_key: "반환받은 PCD_AUTH_KEY", request_key: "반환받은 PCD_PAY_REQKEY값")
```

정기 결제 일 경우
```ruby
Payple.cpay.cert_confirm(cert_url: "반환받은 PCD_PAY_COFURL", auth_key: "반환받은 PCD_AUTH_KEY", request_key: "반환받은 PCD_PAY_REQKEY값", payer_id: "카드등록 후 리턴받은 빌링키(PCD_PAYER_ID)")
```

### 환불하기
```ruby
Payple.cpay.refund(oid: "환불할 oid", pay_date: "YYYYMMDD 형식의 결제 일시 혹은 ruby Date, Time, DateTime 형식", refund_total: "환불할 금액. 총 금액보다 작으면 부분환불됨")
```

## 인증요청

### 간편결제(비밀번호, 일회성), 앱카드결제 가맹점 인증 요청
배열의 첫번째 요소로 다음 결제 url, 두번째 요소로 인증과 관련된 정보가 출력된다.
```ruby
Payple.cpay.auth
=> [
  "https://democpay.payple.kr/index.php?ACT_=PAYM&CPAYVER=202102051731", 
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
Payple.cpay.auth({PCD_PAYCHK_FLAG: "Y"})
=> [
  "https://democpay.payple.kr/php/PayChkAct.php", 
  {
    :PCD_CST_ID=>"N2hQWnYrZFpYc1crYnpiR1dTMzdzQT09", 
    :PCD_CUST_KEY=>"V3lNUzNXNU4wNW1uZlFMejFGdktyQT09", 
    :PCD_AUTH_KEY=>"K0VnWlZ5TWZSaGNla1Vpay96YnNQQTFnYXcyVWxlSzJGTHdtNHpNTndIUmJIZ2IrUFI1VExnZzhvOGNqS2MwR0RXL2ZVVjNXbUNBSG43ajdJNXJlelZuKzBXenZNa2RQSGMwdzJlNndBS3dwMTF4Y29OMkdEaFI4RjZSQVpidVpkNkprbkcwalF0L05xaVFOSXk4WWZqUVg2YUJNSnJiTEFwT05WOXhzSWRaRGFWN1NxeitkTkdWeDFjV2l6dVVRakZ0MVVGWTA0ZW9rZWlvbE0xNmZHRGlyczNrWEtTUkhxakpoWDhqWTFxUUF4N1pseW05QTVFbGY5VUs4WExHRDRubEs4Z3JiOTFNS2djKzZLUDN2RVE9PQ=="
  }
]
```

### 결제 내역 조회
```ruby
Payple.cpay.payment(
  pay_type: :transfer,
  oid: 'test201804000001',
  pay_date: '20200320'
)
```

### 정기결제 등록 카드
등록 카드 조회
```ruby
Payple.cpay.payer(payer_id: "PCD_PAYER_ID 값").parsed_response
=> {"PCD_PAY_RST"=>"success", "PCD_PAY_CODE"=>"0000", "PCD_PAY_MSG"=>"회원조회 성공", "PCD_PAY_TYPE"=>"card", "PCD_PAY_BANKACCTYPE"=>"개인", "PCD_PAYER_ID"=>"cVpMejdJVDliM0FrK3U5b3AyY2hOZz09", "...
```

등록 카드 삭제
```ruby
Payple.cpay.delete_payer(payer_id: "PCD_PAYER_ID 값").parsed_response
=> {"PCD_PAY_RST"=>"success", "PCD_PAY_CODE"=>"0000", "PCD_PAY_MSG"=>"회원조회 성공", "PCD_PAY_TYPE"=>"card", "PCD_PAY_BANKACCTYPE"=>"개인", "PCD_PAYER_ID"=>"cVpMejdJVDliM0FrK3U5b3AyY2hOZz09", "...
```

### 정기결제 재결제
월 자동 결제 방지를 사용하는 경우  
pay_month, pay_year를 입력한다.
```ruby
Payple.cpay.payment_again(pay_type: 'card', payer_id: 'PCD_PAYER_ID 값', goods_name: '재결제하는 상품명', pay_total: '결제 하는 상품 금액', pay_year: 2021, pay_month: 01).parsed_response
=> {"PCD_PAY_RST"=>"success", "PCD_PAY_CODE"=>"0000", "PCD_PAY_MSG"=>"회원조회 성공", "PCD_PAY_TYPE"=>"card", "PCD_PAY_BANKACCTYPE"=>"개인", "PCD_PAYER_ID"=>"cVpMejdJVDliM0FrK3U5b3AyY2hOZz09", "...
```

월 자동 결제 방지를 사용하지 않는 경우  
pay_month, pay_year를 입력하지 않는다.
```ruby
Payple.cpay.payment_again(pay_type: 'card', payer_id: 'PCD_PAYER_ID 값', goods_name: '재결제하는 상품명', pay_total: '결제 하는 상품 금액').parsed_response
```

### 그 외 참고사항
[페이플 공식 문서](https://docs.payple.kr/)에서 필수가 아닌 파라미터는 문서에 적힌 키 값을 함수의 인자로 넘기면 원하는 결과가 출력된다.

다음은 CERT 승인하기의 예시이다.

```ruby
Payple.cpay.cert_confirm(cert_url: "반환받은 PCD_PAY_COFURL", auth_key: "반환받은 PCD_AUTH_KEY", PCD_PAY_REQKEY: "반환받은 PCD_PAY_REQKEY값")
```

이런식으로 [페이플 공식 문서](https://docs.payple.kr/)에는 나와있고 이곳에는 설명이 없는 요청변수는 그냥 문서에 적힌 요청변수를 키로 설정하여 값을 넘길 수 있다.
다만 필수 변수는 이 문서에 적힌대로 값을 넘겨야 GEM이 제대로 작동한다.

## 해외 결제

### Configuration

```ruby
Payple.gpay.configure do |config|
  config.service_id = 'demo'
  config.service_key = 'abcd1234567890'
  config.referer = 'http://localhost:3000'
  config.is_test_mode = true
end
```
만약 테스트 상태라면 is_test_mode 값을 true로 설정한다.
referer에 서비스 URL을 넣어야 한다

### 인증 토큰 생성해서 프론트에 보내주기
Rails 기준
```ruby
# Controller 액션 생성
def payple_auth
  render json: Payple.gpay.auth
end
```

access_token과 expires_in 의 배열을 응답한다.

### [결제 정보 가져오기](https://developer.payple.kr/95003782-646b-4481-847d-30d116b367a7)
```ruby
Payple.gpay.payment(service_oid: "반환받은 service_oid")

또는

Payple.gpay.payment(pay_id: "반환받은 pay_id")
```

### [환불하기](https://developer.payple.kr/global/payment-cancel)
```ruby
Payple.gpay.refund(service_oid: "반환받은 service_oid", totalAmount: "환불할 금액", currency: "USD or KRW", resultUrl: '응답 받을 때 사용할 resultUrl')

또는

Payple.gpay.refund(pay_id: "반환받은 pay_id", totalAmount: "환불할 금액", currency: "USD or KRW", resultUrl: '응답 받을 때 사용할 resultUrl')
```

### [정기결제 재결제](https://developer.payple.kr/global/payment-window)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Karoid/payple-rest-client-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/Karoid/payple-rest-client-ruby/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Payple project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Karoid/payple-rest-client-ruby/blob/master/CODE_OF_CONDUCT.md).
