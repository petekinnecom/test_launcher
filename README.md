# Test Launcher -->

Test Launcher takes a search query and tries to figure out what test you want to run. It makes running tests on the command line easy! Super bonus!

You might use Test Launcher for two reasons:

1. You run tests from the command line a lot.
2. You work in a ruby app that contains inline gems/engines with their own test suites.

It was built for Minitest, but it also has basic support for RSpec and ExUnit.

See the __Usages__ section below for some examples.

# Installation

To install:

```
gem install test_launcher
```

Under the hood, it uses git to determine your project root. If you're on an app that's not using git, let me know and I can remove that dependency.

### Usage

Let's suppose you want to run the test `test_name` in your `blog_post_test.rb`.

Without Test Launcher, you might type this:

```
ruby -I test test/models/blog_post_test.rb --name=test_blog_name_thing
```

But with Test Launcher, you can just type this:

```
test_launcher test_blog_name_thing

#=> Found 1 example in 1 file
#=> ruby -I test test/models/blog_post_test.rb --name=test_blog_name_thing
```

What if you want to run a whole file?  Just go for it!

```
test_launcher blog_post_test

#=> ruby -I test test/models/blog_post_test.rb
```

Maybe you'd like to run a whole folder?

```
test_launcher test/models --all

#=> ruby -I test -e 'ARGV.each {|f| require(f)}' test/models/blog_post_test.rb test/models/comment_test.rb
```

You can run specific test methods by line:
```
test_launcher blog_post_test.rb:13

#=> Found 1 example in 1 file
#=> ruby -I test test/models/blog_post_test.rb --name=test_blog_name_thing
```

What if you just have the class name for the test?

```
test_launcher BlogPostTest

#=> ruby -I test test/models/blog_post_test.rb
```

But what if you aren't specific enough?

```
test_launcher test_blog_na

#=> Found 10 test methods in 3 files.
#=> Running most recently edited. Run with '--all' to run all the tests.
#=> ruby -I test test/models/blog_post_test.rb --name=test_blog_name_thing
```

What if you are very specific?
```
test_launcher /Users/username/code/my_repo/test/models/blog_post_test.rb

#=> ruby -I test test/models/blog_post_test.rb
```

Suppose you have multiple files you'd like to run:
```
test_launcher blog_post_test.rb comment_test.rb

#=> ruby -I test -e 'ARGV.each {|f| require(f)}' test/models/blog_post_test.rb test/models/comment_test.rb
```

Or maybe you'd like to run all test methods that match a regular expression:

```
test_launcher 'hello_\w*|goodbye_\w+' --all

#=> Found 2 methods in 2 files.
#=> bundle exec ruby -I test -e "ARGV.push('--name=/hello_\w*|goodbye_\w+/')" -r /src/test/file_1_test.rb -r /src/test/file_2_test.rb
```

### Inline Gems

If you work in an application that has inlined gems/engines, you've probably already experienced pain around running tests. IDEs and editor plugins have a hard time understanding how to run tests for inlined gems when you have opened the project from a parent folder. By looking for Gemfiles and gemspecs, Test Launcher can run your tests in the correct context. If you are using RubyMine in a project with inline gems, see the __RubyMine__ section below.

For example, if `thing_test.rb` is within your inline_gem, you can run:

```
test_launcher thing_test

#=> cd /path/to/inline_gem && ruby -I test test/thing_test.rb
```

You don't have to run Test Launcher from the root of your project either.  It will figure things out, even when using the `--all` flag!

### Spring preloader

Test Launcher will check for the spring/testunit binstubs.  If they are found in the app/gem/engine it will use spring:

```
test_launcher springified_test

#=> cd /path/to/app && spring testunit test/springified_test.rb
```

Test Launcher will not use spring if the `DISABLE_SPRING=1` environment variable is set.

### Priorities

Test Launcher searches for tests based on your input.

Suppose you type `test_launcher thing`.  It will run tests using this priority preference:

1. A single test file
  - matches on `thing_test.rb`

1. A single, specific test method name or partial name
  - `def test_the_thing`

1. Multiple test method names in the same file
  - `def test_the_thing` and `def test_the_other_thing`

1. Any test file based on a generic search
  - runs `stuff_test.rb` because it found the word `thing` inside of it

If your query looks like it's specifying a line number (e.g. `file_test.rb:17`), that search will be preferred.

Any time it matches multiple files, it will default to running the most recently edited file.  You can append `--all` if you want to run all matching tests, even if they are in different engines/gems!


### Running all tests you've changed:

This will find all uncommitted `*_test.rb` files  and pass them to test_launcher to be run.  Use this before you commit so you don't accidentally commit a test you've broken.

```
git diff --name-only --diff-filter=ACMTUXB | grep _test.rb | xargs test_launcher
```

If you've already committed your changes, but want to double check before you push, diff your changes with origin/master:

```
git diff --name-only --diff-filter=ACMTUXB origin/master | grep _test.rb | xargs test_launcher
```

Add this to your `~/.bash_profile` and enjoy!
```
function tdiff()
{
  git diff --name-only --diff-filter=ACMTUXB $@ | grep _test.rb | xargs test_launcher
}

# Now you can:

tdiff

# or

tdiff origin/master
```

Super fun!

### Setup

This gem installs one executable called `test_launcher`.

```
test_launcher test_name_to_find
```

For me, that's way too much to type, so I recommend adding an alias to your `.bash_profile` like so:

```
alias t='test_launcher'

# If you are using RVM, use this: (see below for more details)
alias t='NOEXEC_DISABLE=1 test_launcher'
```

Now you can just type `t` instead of `test_launcher`.  Much nicer!


# RubyMine Support

When working with inline gems/engines, RubyMine has a hard time figuring out what `test` folders to push into the load path for Minitest.  RubyMine also does not understand that in a project with inline engines, some of them may use Spring and some may not.  When working with inline gems/engines/apps in RubyMine, you end up having to 'Edit Configurations...' many times a day.  This is a bummer.

Test Launcher can be used from RubyMine to help alleviate these problems.  Requiring the `test_launcher/rubymine` file in your run configurations will allow Test Launcher to fix RubyMine's test running to do what you want.

To use the RubyMine support:

1. Open your project
1. Click on Run -> 'Edit Configurations...'
1. If you have any run configurations listed under 'Test::Unit/Shoulda/Minitest', use the minus button to remove them.
1. Open the 'Defaults' and click on 'Test::Unit/Shoulda/Minitest'
1. Under 'Ruby Arguments' change:

```
-e $stdout.sync=true;$stderr.sync=true;load($0=ARGV.shift)`
```

Replace it with:

```
-r test_launcher/rubymine
```

1. Run a test.  Test Launcher should report that it is hijacking the test and it will output the command that it has decided to use.

### Debugging Support

Using Test Launcher to hijack your RubyMine run configuration should allow you to debug any test as well without issue.

# Optimizing with RVM

By default, RVM installs a hook to remove the need to run `bundle exec`.  When you run a gem command, it will search your bundle to see if that command is included in your bundle.  If it is, it will run that version of the command.  If it's not in your bundle, then it will fall back to the global gem.  You can read more about it on [rubygems-bundler](https://github.com/rvm/rubygems-bundler).

Test Launcher is not installed in your bundle.  This means that the time that Bundler spends resolving your Gemfile to check if there's a test\_launcher executable in your bundle is wasted.  For most projects, the amount of time this takes is probably unnoticeable.

On projects with lots of dependencies, this wasted time can be significant.

For example, in a large project, we get a nice improvement:

```
$:time test_launcher something_that_no_test_says
#=> Could not find any tests.

#=> real	0m2.214s
#=> user	0m1.407s
#=> sys	  0m1.062s

$:time NOEXEC_DISABLE=1 test_launcher something_that_no_test_says
#=> Could not find any tests.

#=> real	0m1.412s
#=> user	0m0.745s
#=> sys	  0m0.945s
```

I suggest that if you are using RVM, you may as well make this your alias:

```
alias t='NOEXEC_DISABLE=1 test_launcher'
```

# What's going on in there?

Test Launcher began life as a bash script patching together `ag`, `awk`, `grep`, and all sorts of insanity. After looking up how to do an if/else in bash for the millionth time, I decided to rewrite it in Ruby.

Test Launcher was developed using "BDD" (Bug Driven Development). Because I use it so heavily, I'd pop over and hack something precisely at the moment I needed it (often breaking all sorts of other things). I've since added some tests, but I reserve the right to break anything at anytime if only for old times' sake.
