GitView is browser based git log viewer

## Requirements

* Ruby

## How to use

```
$ git clone git@github.com:maeharin/gitview.git

$ cd ./gitview

$ bundle install --path vendor/bundle

# Ex: visualize cloned rails repo (~/github/rails)
# $ bundle exec ruby ./scripts/import.rb ~/github/rails
$ bundle exec ruby ./scripts/import.rb **git repository path**

$ bundle exec shotgun
```

see http://localhost:9393/

![rails commit](https://github.com/maeharin/gitview/raw/master/screen_shot.png)
