# Changelog

## 1.0.0 (2026-05-19)

### Added
- Initial release covering all 42 Wise Platform API groups
- Token-bucket rate limiter (`Wise.Internal.RateLimiter`) backed by a `GenServer`
- Circuit breaker (`Wise.Internal.CircuitBreaker`) with CLOSED/OPEN/HALF_OPEN states
- Exponential back-off retry with `:crypto.strong_rand_bytes/1` jitter
- HMAC-SHA256 webhook signature verification (constant-time comparison)
- Three authentication modes: personal token, client credentials, user token
- Request/response hook middleware
- HTTPoison connection pooling via `Wise.Application`
- `Wise.IdempotencyKey.new/0` for exactly-once transfer semantics
- Full `@spec` and `@type` annotations throughout
