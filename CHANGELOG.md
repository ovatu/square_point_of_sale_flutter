## 0.2.1

* iOS: route Square POS responses to the request that started them, so payments are not lost when the app runs several Flutter engines (e.g. multiple iPad windows)
* iOS: fail an earlier pending request when a new one starts instead of leaving it waiting forever
* iOS: always include `status` in `requestPayment` error responses

## 0.2.0

* Include status and errors in payment response

## 0.1.3

* Update documentation

## 0.1.2

* Update documentation, format code

## 0.1.1

* Update README

## 0.1.0

* Initial release: Full suppport for Square POS API on both Android and iOS
