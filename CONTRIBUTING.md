# Contributing

Pull requests are always appreciated.

To get started contributing, fork and clone the repo:

```
git clone git@github.com:your-username/hedgelog.git
```

Install development Gems:

```
bundle install
```

Make your code changes.

Make sure that your changes do not break any existing tests:

```
rspec
```

Pull requests will not be accepted for any additional functionality without adding accompanying tests. Moreover, the repository contains a configuration for [Rubocop](https://github.com/bbatsov/rubocop). Pull requests will also not be accepted that do not pass the rubocop style-check. To check this simply run:

```
rubocop
```
