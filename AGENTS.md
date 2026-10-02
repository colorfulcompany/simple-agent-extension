# Test

## Design

 * prefer Unit Test
 * prefer black-box testing
 * prefer dependency-injection with test-specific (sub)class over test-double object ( not prohibitted that )
 * prefer blank-slate with specific behavior over intricate complex real object
 * don't replicate tests in E2E ( tests outside of unit tests ) that are already covered by unit tests
 * group tests for a method using `desribe`
 * specify the conditions in `describe` and the results in `it`
 * avoid helper methods that hide the actual methods being called

## Assertions

Use `power_assert` for test assertions. Prefer its block form for value and
behavior checks:

```ruby
assert { actual == expected }
```

Do not introduce Minitest matcher expectations such as `must_equal` or
`wont_equal`. Use Minitest's exception assertions only when the behavior under
test is raising an error, for example `assert_raises`.

# Ruby Style

Follow StandardRB for Ruby code style and linting.
