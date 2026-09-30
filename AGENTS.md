# Test

## Design

 * prefer Unit Test
 * prefer black-box testing
 * prefer dependency-injection with test-specific (sub)class over test-double object ( not prohibitted that )
 * prefer blank-slate with specific behavior over intricate complex real object

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
